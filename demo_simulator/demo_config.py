"""
demo_config.py — Configuración centralizada del sistema de demo de Tools4Milk.

Todas las constantes, listas de datos realistas y valores de entorno se leen aquí.
Los scripts seed y simulator importan desde este módulo.
"""

import os

# ─────────────────────────────────────────────────────────────────────────────
# VARIABLES DE ENTORNO
# ─────────────────────────────────────────────────────────────────────────────

DEMO_MODE: bool = os.getenv("DEMO_MODE", "false").lower() == "true"
RESET_DEMO_DATA: bool = os.getenv("RESET_DEMO_DATA", "false").lower() == "true"

DATABASE_URL: str = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg://postgres:postgres@localhost:5432/tools4milk",
)

DEMO_ANIMALS: int = int(os.getenv("DEMO_ANIMALS", "120"))
SIM_INTERVAL_SECONDS: int = int(os.getenv("SIM_INTERVAL_SECONDS", "30"))

# ─────────────────────────────────────────────────────────────────────────────
# MARCADORES DE DATOS DEMO (para identificar y limpiar)
# ─────────────────────────────────────────────────────────────────────────────

DEMO_TAG = "[DEMO]"
CROTAL_PREFIX = "DEM-"
DEMO_EMAIL_SUFFIX = "@tools4milk.demo"
DEMO_ESTACION_ID = "DEMO_LUGO_01"

# ─────────────────────────────────────────────────────────────────────────────
# ENUMS VÁLIDOS (verificados en auditoría, NO modificar)
# ─────────────────────────────────────────────────────────────────────────────

ROLES_EMPLEADO = ["encargado", "auxiliar", "veterinario", "mecanico"]
TIPOS_MAQUINARIA = ["robot_ordeno", "carro_mezclador", "amamantadora", "bomba", "otro"]
ESTADOS_ANIMAL = ["produccion", "seca", "recria", "gestante", "baja"]
ESTADOS_REPRODUCTIVOS = ["vacia", "en_celo", "inseminada", "confirmada_gestante", "parto_reciente"]
TIPOS_TURNO = ["manana", "tarde"]
ESTADOS_PEDIDO = ["solicitado", "aprobado", "en_transito", "recibido", "cancelado"]
TIPOS_INCIDENCIA = ["averia_maquinaria", "infraestructura", "sanidad_animal", "calidad_leche", "alimentacion", "pedidos"]
SEVERIDADES = ["baja", "media", "alta"]
ESTADOS_INCIDENCIA = ["abierta", "en_gestion", "resuelta", "cerrada"]
NIVELES_ALERTA = ["baja", "media", "alta"]  # NO usar "critica" (no está en enum DB)
ESTADOS_TAREA_DB = ["pendiente", "en_curso", "completada", "vencida", "cancelada"]

# ─────────────────────────────────────────────────────────────────────────────
# DATOS REALISTAS — EMPLEADOS
# ─────────────────────────────────────────────────────────────────────────────

EMPLEADOS_DEMO = [
    # encargados
    {"nombre": "Carlos", "apellidos": "Rodríguez Peña", "rol": "encargado", "cualificaciones": ["VMS", "TMR"]},
    {"nombre": "Ana", "apellidos": "López Vázquez", "rol": "encargado", "cualificaciones": ["VMS", "veterinaria"]},
    # auxiliares
    {"nombre": "Miguel", "apellidos": "García Fernández", "rol": "auxiliar", "cualificaciones": []},
    {"nombre": "Rosa", "apellidos": "Martínez Iglesias", "rol": "auxiliar", "cualificaciones": ["TMR"]},
    {"nombre": "Xoán", "apellidos": "Castro Otero", "rol": "auxiliar", "cualificaciones": []},
    {"nombre": "Pilar", "apellidos": "Díaz Nóvoa", "rol": "auxiliar", "cualificaciones": ["VMS"]},
    # veterinarios
    {"nombre": "Beatriz", "apellidos": "Suárez Méndez", "rol": "veterinario", "cualificaciones": ["veterinaria"]},
    {"nombre": "Tomás", "apellidos": "González Ramos", "rol": "veterinario", "cualificaciones": ["veterinaria"]},
    # mecánicos
    {"nombre": "Andrés", "apellidos": "Fernández Blanco", "rol": "mecanico", "cualificaciones": ["VMS"]},
    {"nombre": "Lucía", "apellidos": "Álvarez Pardo", "rol": "mecanico", "cualificaciones": []},
    # extra
    {"nombre": "Jorge", "apellidos": "Soto Brea", "rol": "auxiliar", "cualificaciones": ["TMR"]},
    {"nombre": "Elena", "apellidos": "Vidal Caamaño", "rol": "veterinario", "cualificaciones": ["veterinaria"]},
]

# ─────────────────────────────────────────────────────────────────────────────
# DATOS REALISTAS — MAQUINARIA ADICIONAL
# ─────────────────────────────────────────────────────────────────────────────

MAQUINARIA_ADICIONAL = [
    # (nombre, tipo, marca, modelo)
    ("Tanque de leche 6000L", "otro", "DeLaval", "DXCE6000"),
    ("Bomba de vacío principal", "bomba", "DeLaval", "VP3000"),
    ("Amamantadora digital", "amamantadora", "Förster", "HL200 Pro"),
    ("Arrobadera automática", "otro", "Lely", "Discovery 120"),
    ("Equipo de alimentación", "carro_mezclador", "Trioliet", "Unifeed 10"),
    ("Sensor temperatura ambiental", "otro", "Skov", "CS-3000"),
    ("Bomba impulsión purines", "bomba", None, None),
]

# ─────────────────────────────────────────────────────────────────────────────
# DATOS REALISTAS — ANIMALES
# ─────────────────────────────────────────────────────────────────────────────

RAZAS = ["Frisona", "Frisona", "Frisona", "Jersey", "Cruce Frisona-Jersey"]

# Distribución de estados (porcentajes, suma = 100)
DISTRIBUCION_ESTADO = {
    "produccion": 55,
    "seca": 15,
    "recria": 20,
    "gestante": 8,
    "baja": 2,
}

# Estado reproductivo por estado animal
ESTADO_REPRO_POR_ESTADO = {
    "produccion": ["vacia", "en_celo", "inseminada", "confirmada_gestante"],
    "seca": ["confirmada_gestante", "vacia"],
    "gestante": ["confirmada_gestante", "parto_reciente"],
    "recria": None,  # NULL
    "baja": None,    # NULL
}

# ─────────────────────────────────────────────────────────────────────────────
# DATOS REALISTAS — TRATAMIENTOS
# ─────────────────────────────────────────────────────────────────────────────

FARMACOS = [
    ("Cloxacilina 500mg", "intramamaria", 5),
    ("Meloxicam 20mg/ml", "IV", 3),
    ("Oxitetraciclina 200mg/ml", "IM", 4),
    ("Ketoprofeno 100mg/ml", "IV", 3),
    ("Calcio oral 300ml", "oral", 7),
    ("Electrolitos rehidratación", "oral", 5),
    ("Propóleo tópico", "topica", 10),
    ("Vitamina E+Selenio", "IM", 1),
]

# ─────────────────────────────────────────────────────────────────────────────
# DATOS REALISTAS — INCIDENCIAS
# ─────────────────────────────────────────────────────────────────────────────

TITULOS_INCIDENCIA = {
    "averia_maquinaria": [
        "[DEMO] Fallo en brazo de ordeño robot VMS",
        "[DEMO] Error sensor de leche robot 2",
        "[DEMO] Avería bomba de vacío principal",
        "[DEMO] Fallo en lavado automático robot 3",
        "[DEMO] Motor carro mezclador ruidoso",
    ],
    "infraestructura": [
        "[DEMO] Fuga de agua en bebedero zona recría",
        "[DEMO] Puerta automatizada atascada paridera",
        "[DEMO] Iluminación defectuosa sala ordeño",
        "[DEMO] Canaleta obstruida becerrero",
    ],
    "sanidad_animal": [
        "[DEMO] Cojera leve detectada en animal",
        "[DEMO] Posible mastitis subclínica",
        "[DEMO] Diarrea neonatal ternero",
        "[DEMO] Animal con fiebre post-parto",
    ],
    "calidad_leche": [
        "[DEMO] RCS elevado en tanque lote mañana",
        "[DEMO] Conductividad anómala cuarto posterior",
        "[DEMO] Resto antibiótico detectado control",
    ],
    "alimentacion": [
        "[DEMO] Desviación ración TMR superior 8%",
        "[DEMO] Silo forraje con humedad excesiva",
        "[DEMO] Rotura tolva concentrado",
    ],
    "pedidos": [
        "[DEMO] Retraso entrega pezoneras VMS",
        "[DEMO] Stock crítico desinfectante pezones",
    ],
}

# ─────────────────────────────────────────────────────────────────────────────
# DATOS REALISTAS — ALERTAS
# ─────────────────────────────────────────────────────────────────────────────

TITULOS_ALERTA = {
    "alta": [
        "[DEMO] Tarea de ordeño retrasada más de 2h",
        "[DEMO] Tratamiento no administrado hoy",
        "[DEMO] Animal sin ordeñar en última sesión",
        "[DEMO] RCS estimado supera umbral",
    ],
    "media": [
        "[DEMO] Retraso inicio ordeño turno tarde",
        "[DEMO] Desviación ración TMR detectada",
        "[DEMO] Bebedero sin actividad zona becerrero",
        "[DEMO] Temperatura animal fuera de rango",
    ],
    "baja": [
        "[DEMO] Recordatorio protocolo bioseguridad",
        "[DEMO] Estado meteorológico adverso previsto",
        "[DEMO] Mantenimiento preventivo robot próximo",
        "[DEMO] Revisión mensual programación pendiente",
    ],
}

# ─────────────────────────────────────────────────────────────────────────────
# DATOS REALISTAS — PEDIDOS
# ─────────────────────────────────────────────────────────────────────────────

INSUMOS_PEDIDOS = [
    ("[DEMO] Pezoneras VMS DeLaval", "ud", 48, "DeLaval Ibérica", 3.50),
    ("[DEMO] Detergente alcalino limpieza robot", "L", 20, "Ecolab", 8.20),
    ("[DEMO] Detergente ácido neutralizador", "L", 15, "Ecolab", 7.80),
    ("[DEMO] Pienso recría 4-12 semanas", "kg", 500, "NANTA", 0.45),
    ("[DEMO] Guantes nitrilo azul talla L", "caja", 10, "Suministros Ganaderos SA", 12.00),
    ("[DEMO] Yodo postordeño 0.5%", "L", 30, "Laboratorios Hipra", 2.40),
    ("[DEMO] Filtros manga leche 50ud", "paquete", 5, "AgroVet", 18.50),
    ("[DEMO] Paja de trigo granulada", "fardo", 20, "Agrícola del Norte", 6.00),
    ("[DEMO] Leche en polvo maternizadora", "kg", 50, "NANTA", 3.90),
    ("[DEMO] Catéter intramamario desechable", "caja100", 2, "Hipra", 42.00),
    ("[DEMO] Aceite lubricante bomba vacío", "L", 5, "Industrial Lugo", 15.00),
    ("[DEMO] Cornamenta registro electrónico", "ud", 25, "Allflex", 8.50),
]

# ─────────────────────────────────────────────────────────────────────────────
# DATOS REALISTAS — METEOROLOGÍA LUGO/GALICIA
# ─────────────────────────────────────────────────────────────────────────────

METEO_RANGES = {
    "temperatura_c": (8.0, 18.0),
    "humedad_relativa": (70.0, 96.0),
    "precipitacion_mm": (0.0, 14.0),
    "viento_km_h": (4.0, 26.0),
    "radiacion_wm2": (20.0, 450.0),
}

# Probabilidad de lluvia por hora (0-1)
PROB_LLUVIA = 0.35

# ─────────────────────────────────────────────────────────────────────────────
# ROLES EN TURNO (texto libre en asignaciones_turno.rol)
# ─────────────────────────────────────────────────────────────────────────────

ROLES_TURNO = [
    "responsable_ordeno",
    "auxiliar_recria",
    "auxiliar_ordeno",
    "veterinario",
    "mantenimiento",
    "alimentacion",
    "responsable_turno",
]

# ─────────────────────────────────────────────────────────────────────────────
# TABLAS CRÍTICAS A VALIDAR ANTES DE INSERTAR
# ─────────────────────────────────────────────────────────────────────────────

TABLAS_CRITICAS = [
    "zonas",
    "empleados",
    "maquinaria",
    "animales",
    "lactaciones",
    "tratamientos_activos",
    "incidencias",
    "alertas",
    "tareas_catalogo",
    "tareas_ejecuciones",
    "turnos",
    "asignaciones_turno",
    "pedidos",
    "resumenes_relevo",
    "lecturas_meteorologia",
]
