import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.tools4milk import Incidencia


def get_all(db: Session, skip: int = 0, limit: int = 50) -> list[Incidencia]:
    query = select(Incidencia).order_by(Incidencia.ts_apertura.desc())
    return list(db.scalars(query.offset(skip).limit(limit)).all())


def get_by_id(db: Session, incident_id: str) -> Incidencia | None:
    try:
        uid = uuid.UUID(incident_id)
    except (ValueError, AttributeError):
        return None
    return db.get(Incidencia, uid)


def create(db: Session, data: dict) -> Incidencia:
    item = Incidencia(
        id=uuid.uuid4(),
        tipo=data.get("tipo", "infraestructura"),
        subtipo=data.get("subtipo"),
        severidad=data.get("prioridad") or data.get("severidad", "media"),
        estado="abierta",
        titulo=data.get("titulo") or data.get("descripcion", "Nueva incidencia")[:200],
        descripcion=data.get("descripcion"),
        zona_id=_to_uuid(data.get("zona_id")),
        maquinaria_id=_to_uuid(data.get("maquinaria_id")),
        animal_id=_to_uuid(data.get("animal_id")),
        reportado_por=_to_uuid(data.get("reportado_por")),
        ts_apertura=datetime.now(tz=timezone.utc),
        acciones=[],
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def update(db: Session, item: Incidencia, data: dict) -> Incidencia:
    allowed = {"tipo", "subtipo", "severidad", "estado", "titulo", "descripcion",
               "foto_url", "acciones"}
    for key, value in data.items():
        if key == "prioridad":
            item.severidad = value
        elif key == "fecha_resolucion":
            if value:
                try:
                    item.ts_cierre = datetime.fromisoformat(value.replace("Z", "+00:00"))
                except (ValueError, AttributeError):
                    pass
        elif key in allowed:
            setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return item


def _to_uuid(value: str | None) -> uuid.UUID | None:
    if not value:
        return None
    try:
        return uuid.UUID(value)
    except (ValueError, AttributeError):
        return None
