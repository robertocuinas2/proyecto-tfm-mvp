from typing import Any

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.enums import EstadoAnimal, EstadoTarea
from app.models.tools4milk import Alerta, Animal, TareaEjecucion, TratamientoActivo, Zona
from app.routers.deps import DbSession
from app.security import get_current_user

router = APIRouter(prefix="/api/v1", tags=["Frontend Core"], dependencies=[Depends(get_current_user)])


@router.get("/dashboard/summary")
def dashboard_summary(db: DbSession) -> dict[str, Any]:
    pending_alerts = db.scalars(select(Alerta).where(Alerta.activa.is_(True))).all()
    return {
        "alertas": {
            "total_pendientes": len(pending_alerts),
            "criticas": 0,
            "altas": len([a for a in pending_alerts if a.nivel == "alta"]),
        },
        "tareas": {
            "programadas": db.scalar(select(func.count()).select_from(TareaEjecucion).where(TareaEjecucion.estado == EstadoTarea.PENDIENTE)) or 0,
            "ejecutadas": db.scalar(select(func.count()).select_from(TareaEjecucion).where(TareaEjecucion.estado == EstadoTarea.COMPLETADA)) or 0,
            "retrasadas": db.scalar(select(func.count()).select_from(TareaEjecucion).where(TareaEjecucion.estado == EstadoTarea.VENCIDA)) or 0,
        },
        "animales": {
            "activos": db.scalar(select(func.count()).select_from(Animal).where(Animal.estado != EstadoAnimal.BAJA)) or 0,
            "por_zona": _animals_by_zone(db),
        },
        "tratamientos": {
            "activos": db.scalar(select(func.count()).select_from(TratamientoActivo).where(TratamientoActivo.activo.is_(True))) or 0,
        },
    }


def _animals_by_zone(db: Session) -> list[dict[str, Any]]:
    # Solo zonas operativas que albergan animales (nombres canónicos de init.sql /
    # migración baseline). Excluye Oficina y General.
    VALID_ZONE_NAMES = {"Boxes", "Enfermería", "Nave", "Recría"}
    rows = (
        db.execute(
            select(Zona.id, Zona.nombre, func.count(Animal.id).label("total"))
            .outerjoin(Animal, (Animal.zona_id == Zona.id) & (Animal.estado != EstadoAnimal.BAJA))
            .where(Zona.nombre.in_(VALID_ZONE_NAMES))
            .group_by(Zona.id, Zona.nombre)
            .order_by(Zona.nombre)
        ).all()
    )
    return [{"zona_id": str(r.id), "nombre": r.nombre, "total": r.total} for r in rows]
