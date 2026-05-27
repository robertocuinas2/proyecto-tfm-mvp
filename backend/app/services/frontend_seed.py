from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.demo_data import ANIMALS, EMPLOYEES, LACTATIONS, MACHINERY, TASKS, TREATMENTS, ZONES
from app.models import (
    CoreAnimal,
    CoreEmployee,
    CoreLactation,
    CoreMachinery,
    CoreTask,
    CoreTreatment,
    CoreZone,
)


def parse_datetime(value: str | None) -> datetime | None:
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00")).replace(tzinfo=None)


def ensure_frontend_seed_data(db: Session) -> None:
    zone_count = db.scalar(select(func.count()).select_from(CoreZone)) or 0
    animal_count = db.scalar(select(func.count()).select_from(CoreAnimal)) or 0
    task_count = db.scalar(select(func.count()).select_from(CoreTask)) or 0
    lactation_count = db.scalar(select(func.count()).select_from(CoreLactation)) or 0
    treatment_count = db.scalar(select(func.count()).select_from(CoreTreatment)) or 0
    employee_count = db.scalar(select(func.count()).select_from(CoreEmployee)) or 0
    machinery_count = db.scalar(select(func.count()).select_from(CoreMachinery)) or 0

    changed = False
    if zone_count == 0:
        for item in ZONES:
            db.add(CoreZone(**item))
        changed = True

    if animal_count == 0:
        for item in ANIMALS:
            db.add(CoreAnimal(**item))
        changed = True

    if task_count == 0:
        for item in TASKS:
            db.add(
                CoreTask(
                    **{
                        **item,
                        "fecha_programada": parse_datetime(item.get("fecha_programada")),
                        "fecha_ejecucion": parse_datetime(item.get("fecha_ejecucion")),
                        "fecha_seguimiento": parse_datetime(item.get("fecha_seguimiento")),
                    }
                )
            )
        changed = True

    if lactation_count == 0:
        for item in LACTATIONS:
            db.add(CoreLactation(**item))
        changed = True

    if treatment_count == 0:
        for item in TREATMENTS:
            db.add(CoreTreatment(**item))
        changed = True

    if employee_count == 0:
        for item in EMPLOYEES:
            db.add(CoreEmployee(**item))
        changed = True

    if machinery_count == 0:
        for item in MACHINERY:
            db.add(CoreMachinery(**item))
        changed = True

    if changed:
        db.commit()
