from datetime import date
from typing import Any

from app.models.tools4milk import Lactacion


def serialize(l: Lactacion) -> dict[str, Any]:
    activa = l.fecha_secado is None
    dias = None
    if l.fecha_parto:
        ref = l.fecha_secado or date.today()
        dias = (ref - l.fecha_parto).days

    return {
        "id": str(l.id),
        "animal_id": str(l.animal_id),
        "numero_lactacion": l.numero,
        "fecha_inicio": l.fecha_parto.isoformat() if l.fecha_parto else None,
        "fecha_fin": l.fecha_secado.isoformat() if l.fecha_secado else None,
        "dias_transcurridos": dias,
        "produccion_promedio": round(float(l.produccion_total_kg) / 305, 1) if l.produccion_total_kg else None,
        "produccion_total": float(l.produccion_total_kg) if l.produccion_total_kg else None,
        "grasa_promedio": None,
        "proteina_promedio": None,
        "rcs_promedio": None,
        "activa": activa,
    }


def quality_summary(lactaciones: list[Lactacion]) -> dict[str, Any]:
    if not lactaciones:
        return {
            "lactaciones_activas": 0,
            "produccion_promedio": None,
            "grasa_promedio": None,
            "proteina_promedio": None,
            "rcs_promedio": None,
            "animales_en_control": 0,
        }
    return {
        "lactaciones_activas": len(lactaciones),
        "produccion_promedio": round(
            sum(float(l.produccion_total_kg or 0) / 305 for l in lactaciones) / len(lactaciones),
            1,
        ),
        "grasa_promedio": None,
        "proteina_promedio": None,
        "rcs_promedio": None,
        "animales_en_control": len({str(l.animal_id) for l in lactaciones}),
    }
