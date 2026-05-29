"""
seed_realistic_demo_data.py — Poblador de datos demo para Tools4Milk MVP.

Crea una explotación lechera ficticia en la base de datos PostgreSQL con datos
realistas para uso en demostraciones del TFM.

USO:
    DEMO_MODE=true python demo_simulator/seed_realistic_demo_data.py

RESET:
    DEMO_MODE=true RESET_DEMO_DATA=true python demo_simulator/seed_realistic_demo_data.py

Variables de entorno:
    DATABASE_URL       URL de conexión PostgreSQL (default: localhost:5432/tools4milk)
    DEMO_MODE          Debe ser 'true' para ejecutar
    RESET_DEMO_DATA    'true' para limpiar datos demo antes de reinsertar
    DEMO_ANIMALS       Número de animales a crear (default: 120)

IMPORTANTE: Solo toca tablas del esquema Tools4Milk. Nunca borra datos sin marcador demo.
"""

import sys
import os
import uuid
import random
import json
from datetime import datetime, date, timedelta, timezone, time
from decimal import Decimal

# Añadir el directorio actual al path para importar módulos locales
sys.path.insert(0, os.path.dirname(__file__))

from demo_config import (
    DEMO_MODE, RESET_DEMO_DATA, DATABASE_URL, DEMO_ANIMALS,
    DEMO_TAG, CROTAL_PREFIX, DEMO_EMAIL_SUFFIX, DEMO_ESTACION_ID,
    ROLES_EMPLEADO, TIPOS_MAQUINARIA, ESTADOS_ANIMAL, ESTADOS_REPRODUCTIVOS,
    TIPOS_TURNO, ESTADOS_PEDIDO, TIPOS_INCIDENCIA, SEVERIDADES,
    ESTADOS_INCIDENCIA, NIVELES_ALERTA, ESTADOS_TAREA_DB,
    EMPLEADOS_DEMO, MAQUINARIA_ADICIONAL, RAZAS, DISTRIBUCION_ESTADO,
    ESTADO_REPRO_POR_ESTADO, FARMACOS, TITULOS_INCIDENCIA, TITULOS_ALERTA,
    INSUMOS_PEDIDOS, METEO_RANGES, PROB_LLUVIA, ROLES_TURNO,
)
from db import get_engine, validate_tables, fetchall, fetchone, execute, count_demo_records

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def uid() -> str:
    return str(uuid.uuid4())

def today() -> date:
    return date.today()

def now_utc() -> datetime:
    return datetime.now(timezone.utc)

def days_ago(n: int) -> datetime:
    return now_utc() - timedelta(days=n)

def days_from_now(n: int) -> datetime:
    return now_utc() + timedelta(days=n)

def hours_ago(n: float) -> datetime:
    return now_utc() - timedelta(hours=n)

def hours_from_now(n: float) -> datetime:
    return now_utc() + timedelta(hours=n)

def rand_float(lo: float, hi: float, decimals: int = 1) -> float:
    return round(random.uniform(lo, hi), decimals)

def weighted_choice(options: list, weights: list):
    return random.choices(options, weights=weights, k=1)[0]

def log(msg: str):
    print(f"  {msg}")

def section(title: str):
    print(f"\n{'─' * 60}")
    print(f"  {title}")
    print(f"{'─' * 60}")


# ─────────────────────────────────────────────────────────────────────────────
# RESET — Limpiar datos demo
# ─────────────────────────────────────────────────────────────────────────────

def reset_demo_data(conn):
    """
    Elimina SOLO los registros marcados como demo.
    Pide confirmación explícita antes de borrar.
    """
    print("\n⚠️  MODO RESET ACTIVADO")
    print("  Se eliminarán SOLO los registros marcados con prefijos/sufijos demo.")
    confirm = input("  Escribe SI para confirmar: ").strip()
    if confirm != "SI":
        print("  Operación cancelada.")
        sys.exit(0)

    print("\n  Eliminando datos demo...")

    # Orden inverso al de inserción (respetando FK)
    deletes = [
        ("lecturas_meteorologia",  f"estacion_id = '{DEMO_ESTACION_ID}'"),
        ("resumenes_relevo",       f"notas_saliente LIKE '%{DEMO_TAG}%'"),
        ("asignaciones_turno",     f"turno_id IN (SELECT id FROM turnos WHERE notas LIKE '%{DEMO_TAG}%')"),
        ("turnos",                 f"notas LIKE '%{DEMO_TAG}%'"),
        ("alertas",                f"titulo LIKE '[DEMO]%'"),
        ("incidencias",            f"titulo LIKE '[DEMO]%'"),
        ("pedidos",                f"insumo LIKE '[DEMO]%'"),
        ("tareas_ejecuciones",     f"notas LIKE '%{DEMO_TAG}%'"),
        ("tratamientos_activos",   f"animal_id IN (SELECT id FROM animales WHERE crotal_oficial LIKE 'DEM-%')"),
        ("lactaciones",            f"animal_id IN (SELECT id FROM animales WHERE crotal_oficial LIKE 'DEM-%')"),
        ("animales",               f"crotal_oficial LIKE 'DEM-%'"),
        ("maquinaria",             f"notas LIKE '%{DEMO_TAG}%'"),
        ("empleados",              f"email LIKE '%{DEMO_EMAIL_SUFFIX}'"),
    ]

    for table, cond in deletes:
        try:
            result = conn.execute(
                text(f"DELETE FROM {table} WHERE {cond}")
            )
            if result.rowcount > 0:
                log(f"Borrados {result.rowcount} registros demo de '{table}'")
        except Exception as exc:
            log(f"WARN al limpiar '{table}': {exc}")

    conn.commit()
    print("\n  ✓ Datos demo eliminados.")


# ─────────────────────────────────────────────────────────────────────────────
# PASO 1 — Cargar IDs existentes (pre-poblados por init.sql)
# ─────────────────────────────────────────────────────────────────────────────

def load_existing(conn) -> dict:
    """Carga UUIDs e información de tablas pre-pobladas por init.sql."""
    log("Cargando datos existentes...")

    zonas = fetchall(conn, "SELECT id, nombre, codigo FROM zonas ORDER BY nombre")
    maquinaria = fetchall(conn, "SELECT id, nombre, tipo, zona_id FROM maquinaria ORDER BY nombre")
    catalogos = fetchall(conn, "SELECT id, codigo, nombre FROM tareas_catalogo WHERE activa = TRUE ORDER BY nombre")
    umbrales = fetchall(conn, "SELECT id, codigo FROM alertas_umbrales WHERE activo = TRUE ORDER BY codigo")

    log(f"  Zonas encontradas: {len(zonas)}")
    log(f"  Maquinaria encontrada: {len(maquinaria)}")
    log(f"  Catálogo de tareas: {len(catalogos)}")
    log(f"  Umbrales de alerta: {len(umbrales)}")

    if not zonas:
        print("\n[ERROR] No hay zonas en la base de datos.")
        print("  Asegúrate de que init.sql se ejecutó correctamente.")
        sys.exit(1)

    if not catalogos:
        print("\n[ERROR] No hay tareas en el catálogo (tareas_catalogo está vacía).")
        sys.exit(1)

    return {
        "zonas": zonas,
        "zona_ids": [z["id"] for z in zonas],
        "zona_by_codigo": {z["codigo"]: z["id"] for z in zonas},
        "zona_by_nombre": {z["nombre"]: z["id"] for z in zonas},
        "maquinaria": maquinaria,
        "maquinaria_ids": [m["id"] for m in maquinaria],
        "catalogos": catalogos,
        "catalogo_ids": [c["id"] for c in catalogos],
        "umbrales": umbrales,
        "umbral_ids": [u["id"] for u in umbrales],
    }


# ─────────────────────────────────────────────────────────────────────────────
# PASO 2 — Empleados
# ─────────────────────────────────────────────────────────────────────────────

def seed_empleados(conn, existing: dict) -> list[str]:
    """Inserta empleados demo. Retorna lista de IDs insertados."""
    section("EMPLEADOS")

    # Verificar qué empleados demo ya existen
    emails_existentes = {
        row["email"]
        for row in fetchall(conn, f"SELECT email FROM empleados WHERE email LIKE '%{DEMO_EMAIL_SUFFIX}'")
    }

    insertados = []
    for emp in EMPLEADOS_DEMO:
        nombre_slug = f"{emp['nombre'].lower()}.{emp['apellidos'].split()[0].lower()}"
        email = f"{nombre_slug}{DEMO_EMAIL_SUFFIX}"

        if email in emails_existentes:
            # Ya existe, recuperar su ID
            row = fetchone(conn, "SELECT id FROM empleados WHERE email = :email", {"email": email})
            if row:
                insertados.append(str(row["id"]))
            continue

        emp_id = uid()
        cualificaciones = "{" + ",".join(emp.get("cualificaciones", [])) + "}"

        execute(conn, """
            INSERT INTO empleados (id, nombre, apellidos, rol, cualificaciones, email, activo, fecha_alta)
            VALUES (:id, :nombre, :apellidos, :rol, :cual, :email, TRUE, :fecha_alta)
        """, {
            "id": emp_id,
            "nombre": emp["nombre"],
            "apellidos": emp["apellidos"],
            "rol": emp["rol"],
            "cual": cualificaciones,
            "email": email,
            "fecha_alta": today() - timedelta(days=random.randint(30, 1000)),
        })
        insertados.append(emp_id)
        log(f"Empleado: {emp['nombre']} {emp['apellidos']} ({emp['rol']})")

    conn.commit()
    log(f"Total empleados demo disponibles: {len(insertados)}")
    return insertados


def get_empleado_ids_demo(conn) -> list[str]:
    """Recupera todos los IDs de empleados demo."""
    rows = fetchall(conn, f"SELECT id FROM empleados WHERE email LIKE '%{DEMO_EMAIL_SUFFIX}'")
    return [str(r["id"]) for r in rows]


# ─────────────────────────────────────────────────────────────────────────────
# PASO 3 — Maquinaria (asignar zonas a la existente + añadir nueva)
# ─────────────────────────────────────────────────────────────────────────────

def seed_maquinaria(conn, existing: dict) -> list[str]:
    """Asigna zonas a maquinaria existente y añade nueva maquinaria demo."""
    section("MAQUINARIA")

    zona_ids = existing["zona_ids"]
    zona_by_codigo = existing["zona_by_codigo"]

    # Encontrar la zona principal de sala de ordeño para robots VMS
    zona_ordeno = (
        zona_by_codigo.get("sala_ordeno")
        or (zona_ids[0] if zona_ids else None)
    )

    # Actualizar maquinaria existente sin zona asignada
    for maq in existing["maquinaria"]:
        if maq["zona_id"] is None:
            if maq["tipo"] == "robot_ordeno":
                zona_asignar = zona_ordeno
            else:
                zona_asignar = random.choice(zona_ids)
            execute(conn, """
                UPDATE maquinaria SET zona_id = :zona_id WHERE id = :id
            """, {"zona_id": zona_asignar, "id": str(maq["id"])})
            log(f"Zona asignada a maquinaria existente: {maq['nombre']}")

    # Añadir maquinaria adicional demo (si no existe ya con ese nombre)
    nombres_existentes = {m["nombre"] for m in existing["maquinaria"]}
    maq_ids = list(existing["maquinaria_ids"])

    for nombre, tipo, marca, modelo in MAQUINARIA_ADICIONAL:
        if nombre in nombres_existentes:
            continue
        maq_id = uid()
        zona = random.choice(zona_ids)
        execute(conn, """
            INSERT INTO maquinaria (id, nombre, tipo, zona_id, marca, modelo, activa, notas)
            VALUES (:id, :nombre, :tipo, :zona_id, :marca, :modelo, TRUE, :notas)
        """, {
            "id": maq_id,
            "nombre": nombre,
            "tipo": tipo,
            "zona_id": zona,
            "marca": marca,
            "modelo": modelo,
            "notas": f"{DEMO_TAG} Equipo demo",
        })
        maq_ids.append(maq_id)
        log(f"Maquinaria: {nombre} ({tipo})")

    conn.commit()
    return maq_ids


def get_maquinaria_ids(conn) -> list[str]:
    return [str(r["id"]) for r in fetchall(conn, "SELECT id FROM maquinaria WHERE activa = TRUE")]


# ─────────────────────────────────────────────────────────────────────────────
# PASO 4 — Animales
# ─────────────────────────────────────────────────────────────────────────────

def seed_animales(conn) -> list[str]:
    """Crea animales demo con distribución realista."""
    section(f"ANIMALES ({DEMO_ANIMALS})")

    # Verificar cuántos ya existen
    existentes = fetchall(conn, f"SELECT crotal_oficial FROM animales WHERE crotal_oficial LIKE '{CROTAL_PREFIX}%'")
    crotales_existentes = {r["crotal_oficial"] for r in existentes}

    # Construir distribución
    estados = []
    for estado, pct in DISTRIBUCION_ESTADO.items():
        n = round(DEMO_ANIMALS * pct / 100)
        estados.extend([estado] * n)
    random.shuffle(estados)
    # Ajustar al total exacto
    while len(estados) < DEMO_ANIMALS:
        estados.append("produccion")
    estados = estados[:DEMO_ANIMALS]

    animal_ids = []
    # Recuperar IDs de animales demo ya existentes
    for row in fetchall(conn, f"SELECT id FROM animales WHERE crotal_oficial LIKE '{CROTAL_PREFIX}%'"):
        animal_ids.append(str(row["id"]))

    nuevos = 0
    for i in range(1, DEMO_ANIMALS + 1):
        crotal = f"{CROTAL_PREFIX}{i:04d}"
        if crotal in crotales_existentes:
            continue

        estado = estados[i - 1]
        raza = random.choice(RAZAS)

        # Fecha nacimiento coherente con estado
        if estado in ("recria",):
            meses = random.randint(1, 18)
            fecha_nac = today() - timedelta(days=meses * 30)
        elif estado in ("produccion", "seca", "gestante"):
            meses = random.randint(28, 96)  # 2-8 años
            fecha_nac = today() - timedelta(days=meses * 30)
        else:  # baja
            meses = random.randint(36, 96)
            fecha_nac = today() - timedelta(days=meses * 30)

        fecha_entrada = fecha_nac if estado == "recria" else fecha_nac + timedelta(days=random.randint(0, 30))

        # Estado reproductivo
        repro_opciones = ESTADO_REPRO_POR_ESTADO.get(estado)
        estado_repro = random.choice(repro_opciones) if repro_opciones else None

        # Fecha baja para animales con estado 'baja'
        fecha_baja = None
        motivo_baja = None
        if estado == "baja":
            fecha_baja = today() - timedelta(days=random.randint(10, 180))
            motivo_baja = random.choice(["Edad avanzada", "Problema reproductivo", "Enfermedad crónica", "Accidente"])

        animal_id = uid()
        execute(conn, """
            INSERT INTO animales (
                id, crotal_oficial, nombre, sexo, fecha_nacimiento, raza,
                estado, estado_reproductivo, fecha_entrada, fecha_baja, motivo_baja, notas
            ) VALUES (
                :id, :crotal, :nombre, 'hembra', :fecha_nac, :raza,
                :estado, :estado_repro, :fecha_entrada, :fecha_baja, :motivo_baja, :notas
            )
        """, {
            "id": animal_id,
            "crotal": crotal,
            "nombre": None,  # La mayoría sin nombre
            "fecha_nac": fecha_nac,
            "raza": raza,
            "estado": estado,
            "estado_repro": estado_repro,
            "fecha_entrada": fecha_entrada,
            "fecha_baja": fecha_baja,
            "motivo_baja": motivo_baja,
            "notas": f"{DEMO_TAG}",
        })
        animal_ids.append(animal_id)
        nuevos += 1

    conn.commit()
    log(f"Animales nuevos insertados: {nuevos}, total demo disponibles: {len(animal_ids)}")
    return animal_ids


def get_animal_ids_by_estado(conn) -> dict[str, list[str]]:
    """Devuelve IDs de animales demo agrupados por estado."""
    result: dict[str, list[str]] = {}
    for estado in ESTADOS_ANIMAL:
        rows = fetchall(conn, f"""
            SELECT id FROM animales
            WHERE crotal_oficial LIKE '{CROTAL_PREFIX}%' AND estado = :estado
        """, {"estado": estado})
        result[estado] = [str(r["id"]) for r in rows]
    return result


# ─────────────────────────────────────────────────────────────────────────────
# PASO 5 — Lactaciones
# ─────────────────────────────────────────────────────────────────────────────

def seed_lactaciones(conn, animales_por_estado: dict) -> list[str]:
    """Crea lactaciones para animales en producción, seca y gestante."""
    section("LACTACIONES")

    lac_ids = []
    animales_con_lac = set()

    # Verificar lactaciones demo ya existentes
    rows_existentes = fetchall(conn, f"""
        SELECT l.animal_id, l.numero FROM lactaciones l
        JOIN animales a ON a.id = l.animal_id
        WHERE a.crotal_oficial LIKE '{CROTAL_PREFIX}%'
    """)
    existentes_set = {(str(r["animal_id"]), r["numero"]) for r in rows_existentes}
    for r in rows_existentes:
        animales_con_lac.add(str(r["animal_id"]))

    # Animales que pueden tener lactación: produccion, seca, gestante
    candidatos = (
        animales_por_estado.get("produccion", []) +
        animales_por_estado.get("seca", []) +
        animales_por_estado.get("gestante", [])
    )

    nuevas = 0
    for animal_id in candidatos:
        if animal_id in animales_con_lac:
            continue  # ya tiene lactaciones

        # Número de lactaciones históricas (coherente con edad simulada)
        num_historicas = random.randint(0, 3)

        fecha_ref = today() - timedelta(days=random.randint(400, 2400))  # base lejana

        for num in range(1, num_historicas + 2):  # +1 para la activa o última
            key = (animal_id, num)
            if key in existentes_set:
                continue

            fecha_parto = fecha_ref + timedelta(days=random.randint(300, 400) * (num - 1))
            es_activa = (num == num_historicas + 1)
            fecha_secado = None if es_activa else fecha_parto + timedelta(days=random.randint(280, 320))

            # Producción total (solo si está secada o activa con días conocidos)
            if es_activa:
                dias_en_leche = (today() - fecha_parto).days
                prod_diaria = rand_float(22.0, 38.0)
                prod_total = round(prod_diaria * max(dias_en_leche, 1), 2)
            else:
                dias_ciclo = (fecha_secado - fecha_parto).days if fecha_secado else 305
                prod_diaria = rand_float(20.0, 36.0)
                prod_total = round(prod_diaria * dias_ciclo, 2)

            lac_id = uid()
            execute(conn, """
                INSERT INTO lactaciones (id, animal_id, numero, fecha_parto, fecha_secado, produccion_total_kg, notas)
                VALUES (:id, :animal_id, :numero, :fecha_parto, :fecha_secado, :prod_total, :notas)
                ON CONFLICT (animal_id, numero) DO NOTHING
            """, {
                "id": lac_id,
                "animal_id": animal_id,
                "numero": num,
                "fecha_parto": fecha_parto,
                "fecha_secado": fecha_secado,
                "prod_total": prod_total,
                "notas": f"{DEMO_TAG}",
            })
            lac_ids.append(lac_id)
            nuevas += 1

        animales_con_lac.add(animal_id)

    conn.commit()
    log(f"Lactaciones nuevas insertadas: {nuevas}")
    return lac_ids


# ─────────────────────────────────────────────────────────────────────────────
# PASO 6 — Tratamientos activos
# ─────────────────────────────────────────────────────────────────────────────

def seed_tratamientos(conn, animales_por_estado: dict, empleado_ids: list[str]):
    """Crea tratamientos demo."""
    section("TRATAMIENTOS")

    # Verificar cuántos demo ya hay
    ya_hay = count_demo_records(conn, "tratamientos_activos",
        f"animal_id IN (SELECT id FROM animales WHERE crotal_oficial LIKE 'DEM-%')")
    if ya_hay >= 8:
        log(f"Ya existen {ya_hay} tratamientos demo. Saltando.")
        return

    candidatos = (
        animales_por_estado.get("produccion", []) +
        animales_por_estado.get("seca", []) +
        animales_por_estado.get("gestante", [])
    )

    if not candidatos:
        log("Sin animales candidatos para tratamientos.")
        return

    random.shuffle(candidatos)
    total = random.randint(8, 15)
    activos_objetivo = random.randint(5, 8)

    nuevos = 0
    for i, animal_id in enumerate(candidatos[:total]):
        farmaco, via, dias = random.choice(FARMACOS)
        activo = i < activos_objetivo

        if activo:
            dias_offset = random.randint(0, max(0, dias - 1))
            fecha_inicio = today() - timedelta(days=dias_offset)
            fecha_fin_prevista = fecha_inicio + timedelta(days=dias)
            fecha_fin_real = None
        else:
            fecha_inicio = today() - timedelta(days=random.randint(dias + 1, 60))
            fecha_fin_prevista = fecha_inicio + timedelta(days=dias)
            fecha_fin_real = fecha_fin_prevista + timedelta(days=random.randint(0, 2))

        vet_id = random.choice(empleado_ids) if empleado_ids else None

        execute(conn, """
            INSERT INTO tratamientos_activos (
                id, animal_id, farmaco, dosis, via_administracion,
                dias_tratamiento, fecha_inicio, fecha_fin_prevista, fecha_fin_real,
                activo, checkboxes, prescrito_por, notas
            ) VALUES (
                :id, :animal_id, :farmaco, :dosis, :via,
                :dias, :fi, :ffp, :ffr,
                :activo, '[]', :vet_id, :notas
            )
        """, {
            "id": uid(),
            "animal_id": animal_id,
            "farmaco": farmaco,
            "dosis": f"{random.randint(1, 5)} dosis/día",
            "via": via,
            "dias": dias,
            "fi": fecha_inicio,
            "ffp": fecha_fin_prevista,
            "ffr": fecha_fin_real,
            "activo": activo,
            "vet_id": vet_id,
            "notas": f"{DEMO_TAG} tratamiento demo",
        })
        nuevos += 1

    conn.commit()
    log(f"Tratamientos insertados: {nuevos}")


# ─────────────────────────────────────────────────────────────────────────────
# PASO 7 — Turnos y asignaciones
# ─────────────────────────────────────────────────────────────────────────────

def seed_turnos(conn, existing: dict, empleado_ids: list[str]) -> list[str]:
    """Crea turnos para 14 días (7 pasados + hoy + 6 futuros) con asignaciones."""
    section("TURNOS Y ASIGNACIONES")

    zona_ids = existing["zona_ids"]
    turno_ids = []

    # Verificar turnos demo ya existentes
    rows_exist = fetchall(conn, f"SELECT id, fecha, tipo_turno FROM turnos WHERE notas LIKE '%{DEMO_TAG}%'")
    existentes_set = {(str(r["fecha"]), r["tipo_turno"]) for r in rows_exist}
    for r in rows_exist:
        turno_ids.append(str(r["id"]))

    horarios = {
        "manana": (time(6, 0), time(14, 0)),
        "tarde": (time(14, 0), time(22, 0)),
    }

    nuevos_turnos = 0
    nuevas_asignaciones = 0
    fecha_base = today() - timedelta(days=7)

    for dia in range(14):
        fecha_dia = fecha_base + timedelta(days=dia)

        for tipo in ["manana", "tarde"]:
            key = (str(fecha_dia), tipo)
            if key in existentes_set:
                continue

            turno_id = uid()
            hi, hf = horarios[tipo]
            execute(conn, """
                INSERT INTO turnos (id, fecha, tipo_turno, hora_inicio, hora_fin, notas)
                VALUES (:id, :fecha, :tipo, :hi, :hf, :notas)
                ON CONFLICT (fecha, tipo_turno) DO NOTHING
            """, {
                "id": turno_id,
                "fecha": fecha_dia,
                "tipo": tipo,
                "hi": hi,
                "hf": hf,
                "notas": f"{DEMO_TAG}",
            })
            turno_ids.append(turno_id)
            nuevos_turnos += 1

            # Asignaciones: 3-5 empleados por turno
            n_asignados = min(random.randint(3, 5), len(empleado_ids))
            asignados = random.sample(empleado_ids, n_asignados)

            for j, emp_id in enumerate(asignados):
                zona = zona_ids[j % len(zona_ids)] if zona_ids else None
                rol = ROLES_TURNO[j % len(ROLES_TURNO)]
                execute(conn, """
                    INSERT INTO asignaciones_turno (id, turno_id, empleado_id, zona_id, rol)
                    VALUES (:id, :turno_id, :emp_id, :zona_id, :rol)
                    ON CONFLICT (turno_id, empleado_id) DO NOTHING
                """, {
                    "id": uid(),
                    "turno_id": turno_id,
                    "emp_id": emp_id,
                    "zona_id": zona,
                    "rol": rol,
                })
                nuevas_asignaciones += 1

    conn.commit()
    log(f"Turnos nuevos: {nuevos_turnos}, Asignaciones nuevas: {nuevas_asignaciones}")
    log(f"Total turno IDs disponibles: {len(turno_ids)}")
    return turno_ids


def get_turno_ids_demo(conn) -> list[str]:
    return [str(r["id"]) for r in fetchall(conn, f"SELECT id FROM turnos WHERE notas LIKE '%{DEMO_TAG}%' ORDER BY fecha DESC")]


# ─────────────────────────────────────────────────────────────────────────────
# PASO 8 — Tareas ejecuciones
# ─────────────────────────────────────────────────────────────────────────────

def seed_tareas(conn, existing: dict, empleado_ids: list[str]):
    """Crea tareas ejecuciones demo con distribución de estados."""
    section("TAREAS EJECUCIONES")

    catalogo_ids = existing["catalogo_ids"]
    zona_ids = existing["zona_ids"]

    ya_hay = count_demo_records(conn, "tareas_ejecuciones", f"notas LIKE '%{DEMO_TAG}%'")
    if ya_hay >= 50:
        log(f"Ya existen {ya_hay} tareas demo. Saltando.")
        return

    n_total = random.randint(55, 75)
    # Distribución de estados DB
    distribucion = {
        "pendiente": 0.35,
        "vencida": 0.15,
        "completada": 0.35,
        "en_curso": 0.10,
        "cancelada": 0.05,
    }

    estados = []
    for estado, pct in distribucion.items():
        n = round(n_total * pct)
        estados.extend([estado] * n)
    random.shuffle(estados)
    estados = estados[:n_total]

    nuevas = 0
    for estado in estados:
        catalogo_id = random.choice(catalogo_ids)
        zona_id = random.choice(zona_ids) if zona_ids else None
        emp_id = random.choice(empleado_ids) if empleado_ids and random.random() > 0.3 else None

        # Timestamps coherentes con estado
        if estado == "pendiente":
            ts_planificada = hours_from_now(random.uniform(0.5, 8.0))
            ts_inicio = None
            ts_fin = None
        elif estado == "vencida":
            ts_planificada = hours_ago(random.uniform(3.0, 48.0))
            ts_inicio = None
            ts_fin = None
        elif estado == "completada":
            ts_planificada = hours_ago(random.uniform(24.0, 168.0))
            ts_inicio = ts_planificada + timedelta(minutes=random.randint(5, 30))
            duracion = random.randint(15, 90)
            ts_fin = ts_inicio + timedelta(minutes=duracion)
        elif estado == "en_curso":
            ts_planificada = hours_ago(random.uniform(0.5, 3.0))
            ts_inicio = ts_planificada + timedelta(minutes=random.randint(0, 20))
            ts_fin = None
        else:  # cancelada
            ts_planificada = hours_ago(random.uniform(24.0, 72.0))
            ts_inicio = None
            ts_fin = None

        execute(conn, """
            INSERT INTO tareas_ejecuciones (
                id, catalogo_id, empleado_id, zona_id,
                estado, ts_planificada, ts_inicio, ts_fin, notas, creado_en
            ) VALUES (
                :id, :cat_id, :emp_id, :zona_id,
                :estado, :ts_plan, :ts_ini, :ts_fin, :notas, :creado_en
            )
        """, {
            "id": uid(),
            "cat_id": catalogo_id,
            "emp_id": emp_id,
            "zona_id": zona_id,
            "estado": estado,
            "ts_plan": ts_planificada,
            "ts_ini": ts_inicio,
            "ts_fin": ts_fin,
            "notas": f"{DEMO_TAG}",
            "creado_en": now_utc() - timedelta(hours=random.randint(0, 48)),
        })
        nuevas += 1

    conn.commit()
    log(f"Tareas ejecuciones insertadas: {nuevas}")


# ─────────────────────────────────────────────────────────────────────────────
# PASO 9 — Incidencias
# ─────────────────────────────────────────────────────────────────────────────

def seed_incidencias(conn, existing: dict, animales_por_estado: dict,
                     maquinaria_ids: list[str], empleado_ids: list[str]):
    """Crea incidencias demo con vínculos coherentes."""
    section("INCIDENCIAS")

    ya_hay = count_demo_records(conn, "incidencias", f"titulo LIKE '[DEMO]%'")
    if ya_hay >= 15:
        log(f"Ya existen {ya_hay} incidencias demo. Saltando.")
        return

    zona_ids = existing["zona_ids"]
    animales_todos = (
        animales_por_estado.get("produccion", []) +
        animales_por_estado.get("seca", []) +
        animales_por_estado.get("gestante", [])
    )

    n_total = random.randint(18, 25)
    estados_dist = ["abierta"] * 6 + ["en_gestion"] * 6 + ["resuelta"] * 7 + ["cerrada"] * 4
    random.shuffle(estados_dist)
    estados_dist = estados_dist[:n_total]

    tipos_dist = list(TIPOS_INCIDENCIA) * 5
    random.shuffle(tipos_dist)

    nuevas = 0
    for i in range(n_total):
        tipo = tipos_dist[i % len(tipos_dist)]
        estado = estados_dist[i % len(estados_dist)]
        severidad = weighted_choice(["baja", "media", "alta"], [3, 5, 2])
        titulos = TITULOS_INCIDENCIA.get(tipo, ["[DEMO] Incidencia operativa"])
        titulo = random.choice(titulos)

        # Vínculos coherentes según tipo
        zona_id = None
        maq_id = None
        animal_id = None

        if tipo == "averia_maquinaria":
            zona_id = random.choice(zona_ids) if zona_ids else None
            maq_id = random.choice(maquinaria_ids) if maquinaria_ids else None
        elif tipo == "sanidad_animal":
            animal_id = random.choice(animales_todos) if animales_todos else None
        elif tipo in ("infraestructura", "calidad_leche", "alimentacion", "pedidos"):
            zona_id = random.choice(zona_ids) if zona_ids else None

        ts_apertura = now_utc() - timedelta(days=random.randint(0, 30), hours=random.randint(0, 23))
        ts_cierre = None
        if estado in ("resuelta", "cerrada"):
            ts_cierre = ts_apertura + timedelta(hours=random.randint(2, 72))

        reportado_por = random.choice(empleado_ids) if empleado_ids else None

        execute(conn, """
            INSERT INTO incidencias (
                id, tipo, severidad, estado, titulo, descripcion,
                zona_id, maquinaria_id, animal_id, reportado_por,
                ts_apertura, ts_cierre, acciones
            ) VALUES (
                :id, :tipo, :sev, :estado, :titulo, :desc,
                :zona_id, :maq_id, :animal_id, :rep_por,
                :ts_ap, :ts_ci, '[]'
            )
        """, {
            "id": uid(),
            "tipo": tipo,
            "sev": severidad,
            "estado": estado,
            "titulo": titulo,
            "desc": f"Incidencia demo registrada automáticamente para demostración del TFM.",
            "zona_id": zona_id,
            "maq_id": maq_id,
            "animal_id": animal_id,
            "rep_por": reportado_por,
            "ts_ap": ts_apertura,
            "ts_ci": ts_cierre,
        })
        nuevas += 1

    conn.commit()
    log(f"Incidencias insertadas: {nuevas}")


# ─────────────────────────────────────────────────────────────────────────────
# PASO 10 — Alertas
# ─────────────────────────────────────────────────────────────────────────────

def seed_alertas(conn, existing: dict, animales_por_estado: dict, empleado_ids: list[str]):
    """Crea alertas demo."""
    section("ALERTAS")

    ya_hay = count_demo_records(conn, "alertas", f"titulo LIKE '[DEMO]%'")
    if ya_hay >= 20:
        log(f"Ya existen {ya_hay} alertas demo. Saltando.")
        return

    zona_ids = existing["zona_ids"]
    umbral_ids = existing["umbral_ids"]
    animales_todos = (
        animales_por_estado.get("produccion", []) +
        animales_por_estado.get("seca", []) +
        animales_por_estado.get("gestante", [])
    )

    n_total = random.randint(22, 35)
    nuevas = 0

    for _ in range(n_total):
        nivel = weighted_choice(["baja", "media", "alta"], [2, 5, 3])
        titulos = TITULOS_ALERTA.get(nivel, ["[DEMO] Alerta operativa"])
        titulo = random.choice(titulos)

        activa = random.random() > 0.4
        ts_gen = now_utc() - timedelta(days=random.randint(0, 14), hours=random.randint(0, 23))
        ts_res = None
        resuelta_por = None

        if not activa:
            ts_res = ts_gen + timedelta(hours=random.randint(1, 48))
            resuelta_por = random.choice(empleado_ids) if empleado_ids else None

        animal_id = None
        zona_id = None
        if random.random() > 0.4 and animales_todos:
            animal_id = random.choice(animales_todos)
        elif zona_ids:
            zona_id = random.choice(zona_ids)

        umbral_id = random.choice(umbral_ids) if umbral_ids and random.random() > 0.3 else None

        execute(conn, """
            INSERT INTO alertas (
                id, umbral_id, nivel, titulo, mensaje,
                animal_id, zona_id, activa,
                ts_generacion, ts_resolucion, resuelta_por,
                push_whatsapp, pantalla_tv, tablet
            ) VALUES (
                :id, :umbral_id, :nivel, :titulo, :msg,
                :animal_id, :zona_id, :activa,
                :ts_gen, :ts_res, :res_por,
                FALSE, TRUE, TRUE
            )
        """, {
            "id": uid(),
            "umbral_id": umbral_id,
            "nivel": nivel,
            "titulo": titulo,
            "msg": f"Alerta generada por simulador demo. Nivel: {nivel}.",
            "animal_id": animal_id,
            "zona_id": zona_id,
            "activa": activa,
            "ts_gen": ts_gen,
            "ts_res": ts_res,
            "res_por": resuelta_por,
        })
        nuevas += 1

    conn.commit()
    log(f"Alertas insertadas: {nuevas}")


# ─────────────────────────────────────────────────────────────────────────────
# PASO 11 — Pedidos
# ─────────────────────────────────────────────────────────────────────────────

def seed_pedidos(conn, empleado_ids: list[str]):
    """Crea pedidos demo con workflow progresivo."""
    section("PEDIDOS")

    ya_hay = count_demo_records(conn, "pedidos", f"insumo LIKE '[DEMO]%'")
    if ya_hay >= 10:
        log(f"Ya existen {ya_hay} pedidos demo. Saltando.")
        return

    estados_secuencia = [
        "solicitado", "solicitado", "solicitado",
        "aprobado", "aprobado",
        "en_transito", "en_transito",
        "recibido", "recibido", "recibido",
        "cancelado",
    ]

    insumos_sample = random.sample(INSUMOS_PEDIDOS, min(len(INSUMOS_PEDIDOS), len(estados_secuencia)))

    nuevos = 0
    for i, estado in enumerate(estados_secuencia):
        insumo_data = insumos_sample[i % len(insumos_sample)]
        insumo, unidad, cantidad, proveedor, precio_unit = insumo_data

        ts_solic = now_utc() - timedelta(days=random.randint(1, 30))
        ts_aprobacion = None
        ts_recepcion = None

        if estado in ("aprobado", "en_transito", "recibido"):
            ts_aprobacion = ts_solic + timedelta(hours=random.randint(4, 24))
        if estado in ("en_transito", "recibido"):
            pass  # ts_aprobacion ya está
        if estado == "recibido":
            ts_recepcion = ts_aprobacion + timedelta(days=random.randint(2, 7)) if ts_aprobacion else None

        coste_estimado = round(cantidad * precio_unit, 2)
        coste_real = round(coste_estimado * random.uniform(0.95, 1.1), 2) if estado == "recibido" else None
        solicitante = random.choice(empleado_ids) if empleado_ids else None

        execute(conn, """
            INSERT INTO pedidos (
                id, insumo, cantidad, unidad, estado,
                solicitante_id, ts_solicitud, ts_aprobacion, ts_recepcion,
                proveedor, coste_estimado, coste_real, notas
            ) VALUES (
                :id, :insumo, :cant, :unidad, :estado,
                :sol_id, :ts_sol, :ts_apro, :ts_rec,
                :proveedor, :coste_est, :coste_real, :notas
            )
        """, {
            "id": uid(),
            "insumo": insumo,
            "cant": cantidad,
            "unidad": unidad,
            "estado": estado,
            "sol_id": solicitante,
            "ts_sol": ts_solic,
            "ts_apro": ts_aprobacion,
            "ts_rec": ts_recepcion,
            "proveedor": proveedor,
            "coste_est": coste_estimado,
            "coste_real": coste_real,
            "notas": f"{DEMO_TAG}",
        })
        nuevos += 1

    conn.commit()
    log(f"Pedidos insertados: {nuevos}")


# ─────────────────────────────────────────────────────────────────────────────
# PASO 12 — Resúmenes de relevo
# ─────────────────────────────────────────────────────────────────────────────

def seed_resumenes_relevo(conn, turno_ids: list[str], empleado_ids: list[str]):
    """Crea resúmenes de relevo demo."""
    section("RESÚMENES DE RELEVO")

    ya_hay = count_demo_records(conn, "resumenes_relevo", f"notas_saliente LIKE '%{DEMO_TAG}%'")
    if ya_hay >= 5:
        log(f"Ya existen {ya_hay} resúmenes demo. Saltando.")
        return

    if len(turno_ids) < 2:
        log("No hay suficientes turnos para crear resúmenes de relevo.")
        return

    n_resumenes = min(random.randint(5, 10), len(turno_ids) - 1)
    nuevos = 0

    for i in range(n_resumenes):
        idx_sal = i * 2
        idx_ent = idx_sal + 1
        if idx_ent >= len(turno_ids):
            break

        ts_gen = now_utc() - timedelta(days=n_resumenes - i, hours=random.randint(0, 4))
        confirmado = random.random() > 0.4
        confirmado_por = random.choice(empleado_ids) if confirmado and empleado_ids else None
        ts_conf = ts_gen + timedelta(minutes=random.randint(10, 60)) if confirmado else None

        execute(conn, """
            INSERT INTO resumenes_relevo (
                id, turno_saliente_id, turno_entrante_id, ts_generacion,
                incidencias_abiertas, tareas_pendientes, alertas_pendientes,
                notas_saliente, confirmado_por, ts_confirmacion
            ) VALUES (
                :id, :sal_id, :ent_id, :ts_gen,
                :inc, :tareas, :alertas,
                :notas, :conf_por, :ts_conf
            )
        """, {
            "id": uid(),
            "sal_id": turno_ids[idx_sal],
            "ent_id": turno_ids[idx_ent],
            "ts_gen": ts_gen,
            "inc": json.dumps([]),
            "tareas": json.dumps([]),
            "alertas": json.dumps([]),
            "notas": f"{DEMO_TAG} Relevo sin incidencias relevantes.",
            "conf_por": confirmado_por,
            "ts_conf": ts_conf,
        })
        nuevos += 1

    conn.commit()
    log(f"Resúmenes de relevo insertados: {nuevos}")


# ─────────────────────────────────────────────────────────────────────────────
# PASO 13 — Lecturas meteorológicas
# ─────────────────────────────────────────────────────────────────────────────

def seed_meteorologia(conn, n_horas: int = 72):
    """
    Crea lecturas meteorológicas demo para los últimos n_horas.
    estacion_id = DEMO_LUGO_01
    NO inserta columnas GENERATED (indice_thermo_humedad).
    """
    section(f"METEOROLOGÍA ({n_horas} lecturas horarias)")

    ya_hay = count_demo_records(conn, "lecturas_meteorologia", f"estacion_id = '{DEMO_ESTACION_ID}'")
    if ya_hay >= n_horas // 2:
        log(f"Ya existen {ya_hay} lecturas demo. Saltando.")
        return

    base_temp = rand_float(10.0, 15.0)
    base_hum = rand_float(78.0, 88.0)

    nuevas = 0
    for h in range(n_horas, 0, -1):
        ts = now_utc() - timedelta(hours=h)

        # Variación suave entre horas
        temp = round(base_temp + random.uniform(-2.5, 2.5), 1)
        temp = max(6.0, min(20.0, temp))
        hum = round(base_hum + random.uniform(-5.0, 5.0), 1)
        hum = max(65.0, min(98.0, hum))
        llueve = random.random() < PROB_LLUVIA
        precip = round(random.uniform(0.2, 6.0), 1) if llueve else 0.0
        viento = round(random.uniform(4.0, 22.0), 1)
        rad = round(random.uniform(10.0, 400.0), 1)
        dir_viento = random.randint(0, 359)

        try:
            execute(conn, """
                INSERT INTO lecturas_meteorologia (
                    ts, estacion_id,
                    temperatura_c, humedad_relativa, precipitacion_mm,
                    viento_km_h, direccion_viento, radiacion_wm2
                ) VALUES (
                    :ts, :estacion,
                    :temp, :hum, :precip,
                    :viento, :dir, :rad
                )
                ON CONFLICT (ts, estacion_id) DO NOTHING
            """, {
                "ts": ts,
                "estacion": DEMO_ESTACION_ID,
                "temp": temp,
                "hum": hum,
                "precip": precip,
                "viento": viento,
                "dir": dir_viento,
                "rad": rad,
            })
            nuevas += 1
        except Exception:
            pass

    conn.commit()
    log(f"Lecturas meteorológicas insertadas: {nuevas}")


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main():
    print("\n" + "=" * 60)
    print("  Tools4Milk — Seed de datos demo realistas")
    print("=" * 60)

    # Guardia de seguridad
    if not DEMO_MODE:
        print("\n[ABORT] DEMO_MODE no está activo.")
        print("  Ejecuta con: DEMO_MODE=true python demo_simulator/seed_realistic_demo_data.py")
        sys.exit(1)

    print(f"\n  DATABASE_URL : {DATABASE_URL}")
    print(f"  DEMO_ANIMALS : {DEMO_ANIMALS}")
    print(f"  RESET        : {RESET_DEMO_DATA}")

    # Conexión
    engine = get_engine()
    print(f"\n[OK] Conexión a base de datos establecida.")

    # Validación de tablas
    validate_tables(engine)

    with engine.connect() as conn:
        # Reset opcional
        if RESET_DEMO_DATA:
            reset_demo_data(conn)

        # Cargar datos existentes (pre-poblados por init.sql)
        section("CARGANDO DATOS EXISTENTES")
        existing = load_existing(conn)

        # Seed en orden de dependencias
        empleado_ids = seed_empleados(conn, existing)
        if not empleado_ids:
            empleado_ids = get_empleado_ids_demo(conn)

        maquinaria_ids = seed_maquinaria(conn, existing)
        if not maquinaria_ids:
            maquinaria_ids = get_maquinaria_ids(conn)

        animal_ids = seed_animales(conn)
        if not animal_ids:
            animal_ids = [str(r["id"]) for r in fetchall(conn, f"SELECT id FROM animales WHERE crotal_oficial LIKE '{CROTAL_PREFIX}%'")]

        animales_por_estado = get_animal_ids_by_estado(conn)

        seed_lactaciones(conn, animales_por_estado)
        seed_tratamientos(conn, animales_por_estado, empleado_ids)

        turno_ids = seed_turnos(conn, existing, empleado_ids)
        if not turno_ids:
            turno_ids = get_turno_ids_demo(conn)

        seed_tareas(conn, existing, empleado_ids)
        seed_incidencias(conn, existing, animales_por_estado, maquinaria_ids, empleado_ids)
        seed_alertas(conn, existing, animales_por_estado, empleado_ids)
        seed_pedidos(conn, empleado_ids)
        seed_resumenes_relevo(conn, turno_ids, empleado_ids)
        seed_meteorologia(conn, n_horas=72)

    print("\n" + "=" * 60)
    print("  ✓  Seed completado correctamente.")
    print("=" * 60)
    print(f"\n  Animales demo  : {DEMO_ANIMALS} (prefijo '{CROTAL_PREFIX}')")
    print(f"  Marcador demo  : '{DEMO_TAG}' en campos texto")
    print(f"  Emails demo    : '...{DEMO_EMAIL_SUFFIX}'")
    print(f"  Estación meteo : '{DEMO_ESTACION_ID}'")
    print("\n  La aplicación ya debería mostrar datos en todas las pantallas.")
    print("  Ejecuta el simulador para mantenerlos 'vivos': run_live_demo_simulator.py\n")


if __name__ == "__main__":
    main()
