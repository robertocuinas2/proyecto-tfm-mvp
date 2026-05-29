"""
run_live_demo_simulator.py — Simulador vivo de datos demo para Tools4Milk MVP.

Mantiene la base de datos en movimiento durante una demostración: completa tareas,
crea incidencias ocasionales, avanza pedidos, añade lecturas meteo, etc.

USO:
    DEMO_MODE=true python demo_simulator/run_live_demo_simulator.py

    # Con intervalo personalizado (segundos entre ciclos):
    DEMO_MODE=true SIM_INTERVAL_SECONDS=20 python demo_simulator/run_live_demo_simulator.py

Parar con Ctrl+C.
"""

import sys
import os
import uuid
import random
import json
import time
import signal
from datetime import datetime, date, timedelta, timezone

sys.path.insert(0, os.path.dirname(__file__))

from demo_config import (
    DEMO_MODE, DATABASE_URL, SIM_INTERVAL_SECONDS,
    DEMO_TAG, CROTAL_PREFIX, DEMO_EMAIL_SUFFIX, DEMO_ESTACION_ID,
    TITULOS_INCIDENCIA, TITULOS_ALERTA, TIPOS_INCIDENCIA,
    SEVERIDADES, NIVELES_ALERTA, ESTADOS_INCIDENCIA,
    METEO_RANGES, PROB_LLUVIA, ROLES_TURNO,
)
from db import get_engine, fetchall, fetchone, execute

# ─────────────────────────────────────────────────────────────────────────────
# ESTADO GLOBAL
# ─────────────────────────────────────────────────────────────────────────────

running = True
ciclo = 0

def uid() -> str:
    return str(uuid.uuid4())

def now_utc() -> datetime:
    return datetime.now(timezone.utc)

def today() -> date:
    return date.today()

def log_sim(accion: str, detalle: str = ""):
    ts = datetime.now().strftime("%H:%M:%S")
    msg = f"[SIM {ts}] {accion}"
    if detalle:
        msg += f" — {detalle}"
    print(msg)

def handle_sigint(sig, frame):
    global running
    print("\n\n[SIM] Señal de parada recibida. Finalizando limpiamente...")
    running = False

signal.signal(signal.SIGINT, handle_sigint)


# ─────────────────────────────────────────────────────────────────────────────
# CARGA DE IDs DEMO (necesarios para acciones)
# ─────────────────────────────────────────────────────────────────────────────

def load_demo_context(conn) -> dict:
    """Carga IDs de contexto demo para las acciones."""
    zona_ids = [str(r["id"]) for r in fetchall(conn, "SELECT id FROM zonas")]
    empleado_ids = [str(r["id"]) for r in fetchall(conn, f"SELECT id FROM empleados WHERE email LIKE '%{DEMO_EMAIL_SUFFIX}'")]
    catalogo_ids = [str(r["id"]) for r in fetchall(conn, "SELECT id FROM tareas_catalogo WHERE activa = TRUE")]
    animal_ids = [str(r["id"]) for r in fetchall(conn, f"SELECT id FROM animales WHERE crotal_oficial LIKE '{CROTAL_PREFIX}%' AND estado != 'baja'")]
    maquinaria_ids = [str(r["id"]) for r in fetchall(conn, "SELECT id FROM maquinaria WHERE activa = TRUE")]

    if not empleado_ids:
        print("[WARN] No se encontraron empleados demo. Ejecuta primero seed_realistic_demo_data.py")
    if not catalogo_ids:
        print("[WARN] No hay catálogo de tareas. Verifica init.sql.")

    return {
        "zona_ids": zona_ids,
        "empleado_ids": empleado_ids,
        "catalogo_ids": catalogo_ids,
        "animal_ids": animal_ids,
        "maquinaria_ids": maquinaria_ids,
    }


# ─────────────────────────────────────────────────────────────────────────────
# ACCIONES DEL SIMULADOR
# ─────────────────────────────────────────────────────────────────────────────

def accion_completar_tarea(conn, ctx: dict) -> bool:
    """Marca como completada una tarea pendiente demo."""
    row = fetchone(conn, f"""
        SELECT id FROM tareas_ejecuciones
        WHERE estado = 'pendiente'
          AND notas LIKE '%{DEMO_TAG}%'
          AND ts_planificada < :ahora
        ORDER BY RANDOM() LIMIT 1
    """, {"ahora": now_utc()})

    if not row:
        return False

    ts_inicio = now_utc() - timedelta(minutes=random.randint(15, 60))
    ts_fin = now_utc()
    emp_id = random.choice(ctx["empleado_ids"]) if ctx["empleado_ids"] else None

    execute(conn, """
        UPDATE tareas_ejecuciones
        SET estado = 'completada', ts_inicio = :ts_ini, ts_fin = :ts_fin,
            empleado_id = COALESCE(empleado_id, :emp_id)
        WHERE id = :id
    """, {"ts_ini": ts_inicio, "ts_fin": ts_fin, "emp_id": emp_id, "id": str(row["id"])})
    conn.commit()
    log_sim("TAREA COMPLETADA", str(row["id"])[:8] + "…")
    return True


def accion_marcar_vencida(conn) -> bool:
    """Marca como vencidas tareas pendientes con hora planificada pasada +2h."""
    limite = now_utc() - timedelta(hours=2)
    result = execute(conn, f"""
        UPDATE tareas_ejecuciones
        SET estado = 'vencida'
        WHERE estado = 'pendiente'
          AND notas LIKE '%{DEMO_TAG}%'
          AND ts_planificada < :limite
    """, {"limite": limite})
    conn.commit()
    if result.rowcount > 0:
        log_sim(f"TAREAS VENCIDAS", f"{result.rowcount} tareas marcadas como vencidas")
        return True
    return False


def accion_crear_tarea(conn, ctx: dict) -> bool:
    """Crea una nueva tarea demo planificada en el futuro cercano."""
    if not ctx["catalogo_ids"]:
        return False

    catalogo_id = random.choice(ctx["catalogo_ids"])
    zona_id = random.choice(ctx["zona_ids"]) if ctx["zona_ids"] else None
    emp_id = random.choice(ctx["empleado_ids"]) if ctx["empleado_ids"] and random.random() > 0.4 else None
    ts_plan = now_utc() + timedelta(minutes=random.randint(30, 240))

    execute(conn, """
        INSERT INTO tareas_ejecuciones (
            id, catalogo_id, empleado_id, zona_id,
            estado, ts_planificada, notas, creado_en
        ) VALUES (:id, :cat, :emp, :zona, 'pendiente', :ts, :notas, :ahora)
    """, {
        "id": uid(),
        "cat": catalogo_id,
        "emp": emp_id,
        "zona": zona_id,
        "ts": ts_plan,
        "notas": f"{DEMO_TAG}",
        "ahora": now_utc(),
    })
    conn.commit()
    log_sim("TAREA CREADA", f"planificada {ts_plan.strftime('%H:%M')}")
    return True


def accion_crear_incidencia(conn, ctx: dict) -> bool:
    """Crea una incidencia demo ocasional."""
    tipo = random.choice(TIPOS_INCIDENCIA)
    titulos = TITULOS_INCIDENCIA.get(tipo, ["[DEMO] Incidencia operativa"])
    titulo = random.choice(titulos)
    severidad = weighted_choice(["baja", "media", "alta"], [4, 4, 2])

    zona_id = random.choice(ctx["zona_ids"]) if ctx["zona_ids"] else None
    animal_id = None
    maq_id = None

    if tipo == "sanidad_animal" and ctx["animal_ids"]:
        animal_id = random.choice(ctx["animal_ids"])
    elif tipo == "averia_maquinaria" and ctx["maquinaria_ids"]:
        maq_id = random.choice(ctx["maquinaria_ids"])

    rep_por = random.choice(ctx["empleado_ids"]) if ctx["empleado_ids"] else None

    execute(conn, """
        INSERT INTO incidencias (
            id, tipo, severidad, estado, titulo, descripcion,
            zona_id, maquinaria_id, animal_id, reportado_por,
            ts_apertura, acciones
        ) VALUES (
            :id, :tipo, :sev, 'abierta', :titulo, :desc,
            :zona_id, :maq_id, :animal_id, :rep_por,
            :ahora, '[]'
        )
    """, {
        "id": uid(),
        "tipo": tipo,
        "sev": severidad,
        "titulo": titulo,
        "desc": "Incidencia generada por simulador demo.",
        "zona_id": zona_id,
        "maq_id": maq_id,
        "animal_id": animal_id,
        "rep_por": rep_por,
        "ahora": now_utc(),
    })
    conn.commit()
    log_sim("INCIDENCIA CREADA", f"{tipo} / {severidad} — {titulo[:40]}")
    return True


def accion_avanzar_incidencia(conn, ctx: dict) -> bool:
    """Avanza el estado de una incidencia demo abierta."""
    row = fetchone(conn, f"""
        SELECT id, estado FROM incidencias
        WHERE titulo LIKE '[DEMO]%' AND estado IN ('abierta', 'en_gestion')
        ORDER BY RANDOM() LIMIT 1
    """)
    if not row:
        return False

    nuevo_estado = "en_gestion" if row["estado"] == "abierta" else "resuelta"
    ts_cierre = now_utc() if nuevo_estado == "resuelta" else None

    execute(conn, """
        UPDATE incidencias SET estado = :estado, ts_cierre = :ts_ci
        WHERE id = :id
    """, {"estado": nuevo_estado, "ts_ci": ts_cierre, "id": str(row["id"])})
    conn.commit()
    log_sim("INCIDENCIA AVANZADA", f"{row['estado']} → {nuevo_estado}")
    return True


def accion_crear_alerta(conn, ctx: dict) -> bool:
    """Crea una nueva alerta demo."""
    nivel = weighted_choice(["baja", "media", "alta"], [2, 5, 3])
    titulos = TITULOS_ALERTA.get(nivel, ["[DEMO] Alerta operativa"])
    titulo = random.choice(titulos)

    animal_id = random.choice(ctx["animal_ids"]) if ctx["animal_ids"] and random.random() > 0.5 else None
    zona_id = random.choice(ctx["zona_ids"]) if ctx["zona_ids"] and not animal_id else None

    execute(conn, """
        INSERT INTO alertas (
            id, nivel, titulo, mensaje, animal_id, zona_id,
            activa, ts_generacion, push_whatsapp, pantalla_tv, tablet
        ) VALUES (
            :id, :nivel, :titulo, :msg, :animal_id, :zona_id,
            TRUE, :ahora, FALSE, TRUE, TRUE
        )
    """, {
        "id": uid(),
        "nivel": nivel,
        "titulo": titulo,
        "msg": f"Alerta simulada. Nivel: {nivel}.",
        "animal_id": animal_id,
        "zona_id": zona_id,
        "ahora": now_utc(),
    })
    conn.commit()
    log_sim("ALERTA CREADA", f"nivel={nivel} — {titulo[:40]}")
    return True


def accion_resolver_alerta(conn, ctx: dict) -> bool:
    """Resuelve una alerta demo activa."""
    row = fetchone(conn, f"""
        SELECT id FROM alertas
        WHERE titulo LIKE '[DEMO]%' AND activa = TRUE
        ORDER BY ts_generacion ASC LIMIT 1
    """)
    if not row:
        return False

    res_por = random.choice(ctx["empleado_ids"]) if ctx["empleado_ids"] else None
    execute(conn, """
        UPDATE alertas SET activa = FALSE, ts_resolucion = :ts, resuelta_por = :por
        WHERE id = :id
    """, {"ts": now_utc(), "por": res_por, "id": str(row["id"])})
    conn.commit()
    log_sim("ALERTA RESUELTA", str(row["id"])[:8] + "…")
    return True


def accion_avanzar_pedido(conn) -> bool:
    """Avanza el estado de un pedido demo en progreso."""
    row = fetchone(conn, f"""
        SELECT id, estado FROM pedidos
        WHERE insumo LIKE '[DEMO]%'
          AND estado IN ('solicitado', 'aprobado', 'en_transito')
        ORDER BY ts_solicitud ASC LIMIT 1
    """)
    if not row:
        return False

    transiciones = {
        "solicitado": "aprobado",
        "aprobado": "en_transito",
        "en_transito": "recibido",
    }
    nuevo_estado = transiciones.get(row["estado"])
    if not nuevo_estado:
        return False

    updates = {"estado": nuevo_estado, "id": str(row["id"])}
    if nuevo_estado == "aprobado":
        execute(conn, "UPDATE pedidos SET estado=:estado, ts_aprobacion=NOW() WHERE id=:id", updates)
    elif nuevo_estado == "recibido":
        execute(conn, "UPDATE pedidos SET estado=:estado, ts_recepcion=NOW() WHERE id=:id", updates)
    else:
        execute(conn, "UPDATE pedidos SET estado=:estado WHERE id=:id", updates)

    conn.commit()
    log_sim("PEDIDO AVANZADO", f"{row['estado']} → {nuevo_estado}")
    return True


def accion_lectura_meteo(conn) -> bool:
    """Añade una lectura meteorológica demo."""
    # Tomar última temperatura como base
    last = fetchone(conn, f"""
        SELECT temperatura_c, humedad_relativa FROM lecturas_meteorologia
        WHERE estacion_id = '{DEMO_ESTACION_ID}'
        ORDER BY ts DESC LIMIT 1
    """)

    base_temp = float(last["temperatura_c"]) if last and last["temperatura_c"] else 13.0
    base_hum = float(last["humedad_relativa"]) if last and last["humedad_relativa"] else 82.0

    temp = round(base_temp + random.uniform(-1.0, 1.0), 1)
    temp = max(6.0, min(20.0, temp))
    hum = round(base_hum + random.uniform(-2.0, 2.0), 1)
    hum = max(65.0, min(98.0, hum))
    llueve = random.random() < PROB_LLUVIA
    precip = round(random.uniform(0.1, 4.0), 1) if llueve else 0.0
    viento = round(random.uniform(4.0, 20.0), 1)
    rad = round(random.uniform(10.0, 350.0), 1)

    try:
        execute(conn, """
            INSERT INTO lecturas_meteorologia (
                ts, estacion_id, temperatura_c, humedad_relativa,
                precipitacion_mm, viento_km_h, direccion_viento, radiacion_wm2
            ) VALUES (
                :ts, :est, :temp, :hum, :precip, :viento, :dir, :rad
            ) ON CONFLICT (ts, estacion_id) DO NOTHING
        """, {
            "ts": now_utc(),
            "est": DEMO_ESTACION_ID,
            "temp": temp,
            "hum": hum,
            "precip": precip,
            "viento": viento,
            "dir": random.randint(0, 359),
            "rad": rad,
        })
        conn.commit()
        log_sim("METEO", f"T={temp}°C H={hum}% P={precip}mm")
        return True
    except Exception:
        return False


def accion_crear_turno_siguiente(conn, ctx: dict) -> bool:
    """Crea turnos para mañana si aún no existen."""
    manana = today() + timedelta(days=1)

    # ¿Ya existen turnos para mañana?
    row = fetchone(conn, "SELECT COUNT(*) as n FROM turnos WHERE fecha = :fecha", {"fecha": manana})
    if row and row["n"] >= 2:
        return False

    from datetime import time as dtime
    for tipo, hi, hf in [("manana", dtime(6, 0), dtime(14, 0)), ("tarde", dtime(14, 0), dtime(22, 0))]:
        try:
            turno_id = uid()
            execute(conn, """
                INSERT INTO turnos (id, fecha, tipo_turno, hora_inicio, hora_fin, notas)
                VALUES (:id, :fecha, :tipo, :hi, :hf, :notas)
                ON CONFLICT (fecha, tipo_turno) DO NOTHING
            """, {
                "id": turno_id,
                "fecha": manana,
                "tipo": tipo,
                "hi": hi,
                "hf": hf,
                "notas": f"{DEMO_TAG}",
            })

            # Asignaciones: 3 empleados
            if ctx["empleado_ids"]:
                n_emp = min(3, len(ctx["empleado_ids"]))
                asignados = random.sample(ctx["empleado_ids"], n_emp)
                for j, emp_id in enumerate(asignados):
                    zona_id = ctx["zona_ids"][j % len(ctx["zona_ids"])] if ctx["zona_ids"] else None
                    rol = ROLES_TURNO[j % len(ROLES_TURNO)]
                    execute(conn, """
                        INSERT INTO asignaciones_turno (id, turno_id, empleado_id, zona_id, rol)
                        VALUES (:id, :tid, :eid, :zid, :rol)
                        ON CONFLICT (turno_id, empleado_id) DO NOTHING
                    """, {"id": uid(), "tid": turno_id, "eid": emp_id, "zid": zona_id, "rol": rol})

        except Exception:
            pass

    conn.commit()
    log_sim("TURNOS CREADOS", f"Fecha: {manana} (mañana+tarde)")
    return True


def accion_crear_relevo(conn, ctx: dict) -> bool:
    """Crea un resumen de relevo si es hora de cambio de turno."""
    hora_actual = datetime.now().hour
    # Solo cerca del cambio de turno (13-15h o 21-23h)
    if hora_actual not in (13, 14, 21, 22):
        return False

    # Buscar turno saliente de hoy
    row_sal = fetchone(conn, f"""
        SELECT id FROM turnos
        WHERE fecha = :hoy AND notas LIKE '%{DEMO_TAG}%'
        ORDER BY hora_inicio LIMIT 1
    """, {"hoy": today()})
    row_ent = fetchone(conn, f"""
        SELECT id FROM turnos
        WHERE fecha = :hoy AND notas LIKE '%{DEMO_TAG}%'
        ORDER BY hora_inicio DESC LIMIT 1
    """, {"hoy": today()})

    if not row_sal or not row_ent or str(row_sal["id"]) == str(row_ent["id"]):
        return False

    # Verificar que no existe ya relevo hoy
    existe = fetchone(conn, f"""
        SELECT id FROM resumenes_relevo
        WHERE turno_saliente_id = :sal AND notas_saliente LIKE '%{DEMO_TAG}%'
    """, {"sal": str(row_sal["id"])})
    if existe:
        return False

    conf_por = random.choice(ctx["empleado_ids"]) if ctx["empleado_ids"] else None
    execute(conn, """
        INSERT INTO resumenes_relevo (
            id, turno_saliente_id, turno_entrante_id, ts_generacion,
            incidencias_abiertas, tareas_pendientes, alertas_pendientes,
            notas_saliente, confirmado_por, ts_confirmacion
        ) VALUES (
            :id, :sal, :ent, :ts,
            '[]', '[]', '[]',
            :notas, :conf, :ts_conf
        )
    """, {
        "id": uid(),
        "sal": str(row_sal["id"]),
        "ent": str(row_ent["id"]),
        "ts": now_utc(),
        "notas": f"{DEMO_TAG} Cambio de turno automático.",
        "conf": conf_por,
        "ts_conf": now_utc() + timedelta(minutes=15) if conf_por else None,
    })
    conn.commit()
    log_sim("RELEVO CREADO", f"Turno saliente → entrante")
    return True


# ─────────────────────────────────────────────────────────────────────────────
# SELECCIÓN PONDERADA DE ACCIONES
# ─────────────────────────────────────────────────────────────────────────────

def weighted_choice(options, weights):
    return random.choices(options, weights=weights, k=1)[0]

# Probabilidades por acción (suma de pesos, no necesita sumar 100)
ACCIONES = [
    ("completar_tarea",      8, accion_completar_tarea),
    ("marcar_vencida",       3, None),  # se ejecuta siempre, no necesita ctx
    ("crear_tarea",          5, accion_crear_tarea),
    ("crear_incidencia",     2, accion_crear_incidencia),
    ("avanzar_incidencia",   4, accion_avanzar_incidencia),
    ("crear_alerta",         3, accion_crear_alerta),
    ("resolver_alerta",      5, accion_resolver_alerta),
    ("avanzar_pedido",       4, accion_avanzar_pedido),
    ("lectura_meteo",        6, accion_lectura_meteo),
    ("turno_siguiente",      1, accion_crear_turno_siguiente),
    ("crear_relevo",         1, accion_crear_relevo),
]


def ejecutar_ciclo(conn, ctx: dict):
    """Ejecuta un ciclo del simulador eligiendo 1-2 acciones aleatoriamente."""
    global ciclo
    ciclo += 1
    print(f"\n[SIM] ── Ciclo #{ciclo} ── {datetime.now().strftime('%H:%M:%S')} ──")

    # Siempre: marcar vencidas
    accion_marcar_vencida(conn)

    # Elegir 1-2 acciones adicionales al azar
    n_acciones = random.randint(1, 2)
    pesos = [a[1] for a in ACCIONES if a[2] is not None]
    funcs = [a[2] for a in ACCIONES if a[2] is not None]

    elegidas = random.choices(range(len(funcs)), weights=pesos, k=n_acciones)
    elegidas_unicas = list(dict.fromkeys(elegidas))  # dedup

    for idx in elegidas_unicas:
        func = funcs[idx]
        nombre = ACCIONES[idx][0] if ACCIONES[idx][2] else "desconocida"
        try:
            if func.__code__.co_varnames[0] == "conn" and func.__code__.co_argcount == 1:
                func(conn)
            elif "ctx" in func.__code__.co_varnames:
                func(conn, ctx)
            else:
                func(conn)
        except Exception as exc:
            print(f"  [WARN] Error en acción '{nombre}': {exc}")


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main():
    global running

    print("\n" + "=" * 60)
    print("  Tools4Milk — Simulador de demo en vivo")
    print("=" * 60)

    if not DEMO_MODE:
        print("\n[ABORT] DEMO_MODE no está activo.")
        print("  Ejecuta con: DEMO_MODE=true python demo_simulator/run_live_demo_simulator.py")
        sys.exit(1)

    print(f"\n  DATABASE_URL    : {DATABASE_URL}")
    print(f"  INTERVALO       : {SIM_INTERVAL_SECONDS}s entre ciclos")
    print(f"  DEMO_TAG        : '{DEMO_TAG}'")
    print(f"\n  Presiona Ctrl+C para parar limpiamente.\n")

    engine = get_engine()
    print("[OK] Conexión establecida. Iniciando simulación...\n")

    with engine.connect() as conn:
        ctx = load_demo_context(conn)

        if not ctx["empleado_ids"]:
            print("[ERROR] No hay empleados demo. Ejecuta primero:")
            print("  DEMO_MODE=true python demo_simulator/seed_realistic_demo_data.py")
            sys.exit(1)

        print(f"  Contexto cargado:")
        print(f"    Zonas      : {len(ctx['zona_ids'])}")
        print(f"    Empleados  : {len(ctx['empleado_ids'])}")
        print(f"    Catálogos  : {len(ctx['catalogo_ids'])}")
        print(f"    Animales   : {len(ctx['animal_ids'])}")
        print(f"    Maquinaria : {len(ctx['maquinaria_ids'])}")

        while running:
            try:
                ejecutar_ciclo(conn, ctx)

                # Refrescar contexto cada 10 ciclos
                if ciclo % 10 == 0:
                    ctx = load_demo_context(conn)

                # Esperar hasta el próximo ciclo
                for _ in range(SIM_INTERVAL_SECONDS):
                    if not running:
                        break
                    time.sleep(1)

            except Exception as exc:
                print(f"\n[ERROR] Error en ciclo #{ciclo}: {exc}")
                print("  Reintentando en el próximo ciclo...")
                time.sleep(5)

    print("\n[SIM] Simulador detenido correctamente.")
    print(f"  Ciclos ejecutados: {ciclo}")


if __name__ == "__main__":
    main()
