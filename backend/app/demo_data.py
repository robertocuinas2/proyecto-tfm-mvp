from datetime import timedelta
from typing import Any

from app.time_utils import utc_now


def iso_in(days: int = 0, hours: int = 0) -> str:
    return (utc_now() + timedelta(days=days, hours=hours)).isoformat()


ANIMALS: list[dict[str, Any]] = [
    {
        "id": "animal-001",
        "crotal_oficial": "ES001",
        "nombre": "Luna",
        "sexo": "hembra",
        "fecha_nacimiento": "2020-04-12",
        "raza": "Frisona",
        "estado": "produccion",
        "estado_reproductivo": "lactante",
        "fecha_entrada": "2020-04-12",
    },
    {
        "id": "animal-002",
        "crotal_oficial": "ES002",
        "nombre": "Nube",
        "sexo": "hembra",
        "fecha_nacimiento": "2021-09-03",
        "raza": "Frisona",
        "estado": "produccion",
        "estado_reproductivo": "prenada",
        "fecha_entrada": "2021-09-03",
    },
    {
        "id": "animal-003",
        "crotal_oficial": "ES003",
        "nombre": "Brisa",
        "sexo": "hembra",
        "fecha_nacimiento": "2025-01-19",
        "raza": "Cruce",
        "estado": "recria",
        "estado_reproductivo": None,
        "fecha_entrada": "2025-01-19",
    },
]

ZONES: list[dict[str, Any]] = [
    {
        "id": "ordeno",
        "nombre": "Sala de ordeno",
        "codigo": "ORD",
        "descripcion": "Produccion, calidad de leche y tanque.",
        "tipo": "produccion",
        "tiene_pantalla_tv": True,
        "tiene_tablet": True,
        "activa": True,
    },
    {
        "id": "paridera",
        "nombre": "Paridera",
        "codigo": "PAR",
        "descripcion": "Partos, preparto y atencion neonatal.",
        "tipo": "cuidados",
        "tiene_pantalla_tv": True,
        "tiene_tablet": True,
        "activa": True,
    },
    {
        "id": "recria",
        "nombre": "Recria",
        "codigo": "REC",
        "descripcion": "Terneras, crecimiento y salud de recria.",
        "tipo": "crecimiento",
        "tiene_pantalla_tv": True,
        "tiene_tablet": True,
        "activa": True,
    },
]

TASKS: list[dict[str, Any]] = [
    {
        "id": "task-001",
        "tarea_catalogo_id": "cat-ord-001",
        "tarea_catalogo": {
            "id": "cat-ord-001",
            "nombre": "Revisar tanque",
            "categoria": "ordeno",
            "frecuencia": "diaria",
            "zona_aplicable": "ordeno",
        },
        "zona_id": "ordeno",
        "fecha_programada": iso_in(hours=1),
        "fecha_ejecucion": None,
        "estado": "programada",
        "ejecutado_por": None,
        "tiempo_ejecucion_minutos": None,
        "resultado": None,
        "observaciones": None,
        "checklist_completado": "false",
        "es_urgente": True,
        "requiere_seguimiento": False,
    },
    {
        "id": "task-002",
        "tarea_catalogo_id": "cat-par-001",
        "tarea_catalogo": {
            "id": "cat-par-001",
            "nombre": "Control encamado",
            "categoria": "bienestar",
            "frecuencia": "diaria",
            "zona_aplicable": "paridera",
        },
        "zona_id": "paridera",
        "fecha_programada": iso_in(hours=-4),
        "fecha_ejecucion": None,
        "estado": "retrasada",
        "ejecutado_por": None,
        "tiempo_ejecucion_minutos": None,
        "resultado": None,
        "observaciones": "Pendiente de revision",
        "checklist_completado": "false",
        "es_urgente": False,
        "requiere_seguimiento": True,
    },
]

ALERTS: list[dict[str, Any]] = []

LACTATIONS: list[dict[str, Any]] = [
    {
        "id": "lac-001",
        "animal_id": "animal-001",
        "numero_lactacion": 3,
        "fecha_inicio": "2025-10-02",
        "fecha_fin": None,
        "dias_transcurridos": 236,
        "produccion_promedio": 34.2,
        "produccion_total": 8071.2,
        "grasa_promedio": 3.72,
        "proteina_promedio": 3.31,
        "rcs_promedio": 168000,
        "activa": True,
    },
    {
        "id": "lac-002",
        "animal_id": "animal-002",
        "numero_lactacion": 2,
        "fecha_inicio": "2025-11-18",
        "fecha_fin": None,
        "dias_transcurridos": 189,
        "produccion_promedio": 30.8,
        "produccion_total": 5821.2,
        "grasa_promedio": 3.84,
        "proteina_promedio": 3.39,
        "rcs_promedio": 142000,
        "activa": True,
    },
]

TREATMENTS: list[dict[str, Any]] = [
    {
        "id": "treat-001",
        "animal_id": "animal-002",
        "medicamento": "Suplemento mineral",
        "dosis": "120 g/dia",
        "via_administracion": "oral",
        "fecha_inicio": "2026-05-20",
        "fecha_fin": None,
        "periodo_retirada_dias": 0,
        "fecha_fin_retirada": None,
        "activo": True,
        "motivo": "Apoyo nutricional en tramo final de gestacion",
        "veterinario": "Dr. Mendez",
        "observaciones": "Revisar condicion corporal semanalmente.",
    }
]

EMPLOYEES: list[dict[str, Any]] = [
    {
        "id": "emp-001",
        "nombre": "Roberto",
        "apellidos": "Castro",
        "role": "admin",
        "zona_principal_id": "ordeno",
        "activo": True,
    },
    {
        "id": "emp-002",
        "nombre": "Laura",
        "apellidos": "Fernandez",
        "role": "alimentacion",
        "zona_principal_id": "recria",
        "activo": True,
    },
    {
        "id": "emp-003",
        "nombre": "Dr.",
        "apellidos": "Mendez",
        "role": "veterinario",
        "zona_principal_id": "paridera",
        "activo": True,
    },
]

MACHINERY: list[dict[str, Any]] = [
    {
        "id": "mach-001",
        "nombre": "Robot de ordeno 1",
        "tipo": "ordeno",
        "zona_id": "ordeno",
        "estado": "operativa",
        "proxima_revision": "2026-06-10",
        "observaciones": "Lavado automatico correcto.",
    },
    {
        "id": "mach-002",
        "nombre": "Mezclador unifeed",
        "tipo": "alimentacion",
        "zona_id": "recria",
        "estado": "revision_programada",
        "proxima_revision": "2026-05-30",
        "observaciones": "Comprobar cuchillas y bascula.",
    },
]


def paginated(items: list[dict[str, Any]], skip: int, limit: int) -> list[dict[str, Any]]:
    return items[skip : skip + limit]
