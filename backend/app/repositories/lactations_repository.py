import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.tools4milk import Lactacion


def get_all(
    db: Session,
    skip: int = 0,
    limit: int = 50,
    animal_id: str | None = None,
    activa: bool | None = None,
) -> list[Lactacion]:
    query = select(Lactacion).order_by(Lactacion.fecha_parto.desc())
    if animal_id is not None:
        try:
            query = query.where(Lactacion.animal_id == uuid.UUID(animal_id))
        except (ValueError, AttributeError):
            return []
    if activa is not None:
        # Activa = fecha_secado es null
        if activa:
            query = query.where(Lactacion.fecha_secado.is_(None))
        else:
            query = query.where(Lactacion.fecha_secado.is_not(None))
    return list(db.scalars(query.offset(skip).limit(limit)).all())


def get_all_active(db: Session) -> list[Lactacion]:
    return list(db.scalars(select(Lactacion).where(Lactacion.fecha_secado.is_(None))).all())


def get_by_id(db: Session, lactation_id: str) -> Lactacion | None:
    try:
        uid = uuid.UUID(lactation_id)
    except (ValueError, AttributeError):
        return None
    return db.get(Lactacion, uid)


def get_active_for_animal(db: Session, animal_id: str) -> Lactacion | None:
    try:
        uid = uuid.UUID(animal_id)
    except (ValueError, AttributeError):
        return None
    return db.scalar(
        select(Lactacion)
        .where(Lactacion.animal_id == uid, Lactacion.fecha_secado.is_(None))
        .order_by(Lactacion.numero.desc())
    )


def create(db: Session, data: dict) -> Lactacion:
    item = Lactacion(
        id=uuid.uuid4(),
        animal_id=uuid.UUID(data["animal_id"]),
        numero=data.get("numero_lactacion") or data.get("numero", 1),
        fecha_parto=_parse_date(data.get("fecha_inicio") or data.get("fecha_parto")),
        fecha_secado=_parse_date(data.get("fecha_fin") or data.get("fecha_secado")),
        produccion_total_kg=data.get("produccion_total"),
        notas=data.get("notas"),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def update(db: Session, item: Lactacion, data: dict) -> Lactacion:
    if "fecha_secado" in data or "fecha_fin" in data:
        item.fecha_secado = _parse_date(data.get("fecha_secado") or data.get("fecha_fin"))
    if "produccion_total" in data:
        item.produccion_total_kg = data["produccion_total"]
    if "notas" in data:
        item.notas = data["notas"]
    db.commit()
    db.refresh(item)
    return item


def _parse_date(value: str | date | None) -> date | None:
    if value is None:
        return None
    if isinstance(value, date):
        return value
    try:
        return date.fromisoformat(str(value)[:10])
    except (ValueError, TypeError):
        return None
