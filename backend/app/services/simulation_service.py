from __future__ import annotations

import random
from dataclasses import dataclass
from datetime import timedelta
from typing import Any
from uuid import uuid4

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.config import settings
from app.models import (
    CoreAlert,
    CoreAnimal,
    CoreEmployee,
    CoreIncident,
    CoreLactation,
    CoreMachinery,
    CoreTask,
    CoreZone,
)
from app.services.frontend_seed import ensure_frontend_seed_data
from app.time_utils import utc_now


TASK_TEMPLATES = [
    ("Revisar tanque de leche", "calidad", "ordeno"),
    ("Comprobar camas y pasillos", "bienestar", "paridera"),
    ("Preparar racion de produccion", "alimentacion", "alimentacion"),
    ("Control visual de recria", "sanidad", "recria"),
    ("Revision rapida de robot", "mantenimiento", "ordeno"),
]

INCIDENT_TYPES = [
    "Sanitaria - seguimiento animal",
    "Operativa - tarea retrasada",
    "Calidad - parametro fuera de objetivo",
    "Maquinaria - revision preventiva",
    "Alimentacion - ajuste de racion",
]


@dataclass(frozen=True)
class SimulationCaps:
    max_tasks: int = settings.simulation_max_tasks
    max_alerts: int = settings.simulation_max_alerts
    max_incidents: int = settings.simulation_max_incidents


def simulation_status(db: Session) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    return {
        "enabled": settings.enable_simulation,
        "counts": _counts(db),
        "caps": {
            "tasks": settings.simulation_max_tasks,
            "alerts": settings.simulation_max_alerts,
            "incidents": settings.simulation_max_incidents,
        },
        "integrity": validate_simulation_integrity(db),
    }


def run_simulation_tick(db: Session, intensity: int = 1) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    intensity = max(1, min(intensity, 5))
    rng = random.Random(f"{utc_now().isoformat()}-{uuid4()}")
    operations: dict[str, int] = {
        "tasks_created": 0,
        "tasks_completed": 0,
        "alerts_created": 0,
        "alerts_resolved": 0,
        "incidents_created": 0,
        "incidents_resolved": 0,
        "lactations_updated": 0,
        "machinery_updated": 0,
        "deleted_old_records": 0,
    }

    for _ in range(intensity):
        operations["tasks_completed"] += _complete_task(db, rng)
        operations["tasks_created"] += _create_task(db, rng)
        operations["alerts_resolved"] += _resolve_alert(db, rng)
        operations["alerts_created"] += _create_alert_from_lactation(db, rng)
        operations["incidents_resolved"] += _resolve_incident(db, rng)
        operations["incidents_created"] += _create_incident(db, rng)
        operations["lactations_updated"] += _update_lactations(db, rng)
        operations["machinery_updated"] += _update_machinery(db, rng)

    operations["deleted_old_records"] += _trim_operational_history(db, SimulationCaps())
    db.commit()

    return {
        "ok": True,
        "timestamp": utc_now().isoformat(),
        "intensity": intensity,
        "operations": operations,
        "counts": _counts(db),
        "integrity": validate_simulation_integrity(db),
    }


def validate_simulation_integrity(db: Session) -> dict[str, Any]:
    animals = db.scalars(select(CoreAnimal.id)).all()
    zones = db.scalars(select(CoreZone.id)).all()
    animal_ids = set(animals)
    zone_ids = set(zones)
    errors: list[str] = []

    for alert in db.scalars(select(CoreAlert)).all():
        if alert.animal_id not in animal_ids:
            errors.append(f"alert {alert.id} references missing animal {alert.animal_id}")

    for lactation in db.scalars(select(CoreLactation)).all():
        if lactation.animal_id not in animal_ids:
            errors.append(f"lactation {lactation.id} references missing animal {lactation.animal_id}")

    for task in db.scalars(select(CoreTask)).all():
        if task.zona_id and task.zona_id not in zone_ids:
            errors.append(f"task {task.id} references missing zone {task.zona_id}")

    for incident in db.scalars(select(CoreIncident)).all():
        if incident.zona_id and incident.zona_id not in zone_ids:
            errors.append(f"incident {incident.id} references missing zone {incident.zona_id}")
        if incident.animal_id and incident.animal_id not in animal_ids:
            errors.append(f"incident {incident.id} references missing animal {incident.animal_id}")

    for machine in db.scalars(select(CoreMachinery)).all():
        if machine.zona_id and machine.zona_id not in zone_ids:
            errors.append(f"machinery {machine.id} references missing zone {machine.zona_id}")

    return {"ok": not errors, "errors": errors}


def _counts(db: Session) -> dict[str, int]:
    return {
        "animals": db.scalar(select(func.count()).select_from(CoreAnimal)) or 0,
        "active_lactations": db.scalar(select(func.count()).select_from(CoreLactation).where(CoreLactation.activa.is_(True))) or 0,
        "pending_alerts": db.scalar(select(func.count()).select_from(CoreAlert).where(CoreAlert.estado == "pendiente")) or 0,
        "tasks": db.scalar(select(func.count()).select_from(CoreTask)) or 0,
        "open_incidents": db.scalar(select(func.count()).select_from(CoreIncident).where(CoreIncident.estado.in_(["abierta", "en_proceso"]))) or 0,
        "machinery": db.scalar(select(func.count()).select_from(CoreMachinery)) or 0,
    }


def _complete_task(db: Session, rng: random.Random) -> int:
    task = db.scalar(
        select(CoreTask)
        .where(CoreTask.estado.in_(["programada", "retrasada"]))
        .order_by(CoreTask.fecha_programada)
    )
    if task is None:
        return 0

    employee = _pick(db.scalars(select(CoreEmployee).where(CoreEmployee.activo.is_(True))).all(), rng)
    task.estado = "ejecutada"
    task.fecha_ejecucion = utc_now().replace(tzinfo=None)
    task.ejecutado_por = employee.nombre if employee else "Simulador"
    task.tiempo_ejecucion_minutos = str(rng.randint(12, 70))
    task.resultado = "ok"
    task.checklist_completado = "true"
    task.motivo_retraso = None
    task.requiere_seguimiento = False
    task.fecha_seguimiento = None
    return 1


def _create_task(db: Session, rng: random.Random) -> int:
    zones = db.scalars(select(CoreZone).where(CoreZone.activa.is_(True))).all()
    zone = _pick(zones, rng)
    if zone is None:
        return 0

    name, category, default_zone = rng.choice(TASK_TEMPLATES)
    planned = utc_now().replace(tzinfo=None) + timedelta(minutes=rng.randint(20, 8 * 60))
    status = "retrasada" if rng.random() < 0.15 else "programada"
    task_id = str(uuid4())
    db.add(
        CoreTask(
            id=task_id,
            tarea_catalogo_id=f"sim-cat-{task_id[:8]}",
            tarea_catalogo={
                "id": f"sim-cat-{task_id[:8]}",
                "nombre": name,
                "categoria": category,
                "frecuencia": "dinamica",
                "zona_aplicable": default_zone,
            },
            zona_id=zone.id,
            fecha_programada=planned,
            estado=status,
            checklist_completado="false",
            es_urgente=status == "retrasada" or rng.random() < 0.2,
            observaciones="Tarea generada por simulacion operativa.",
            requiere_seguimiento=status == "retrasada",
            fecha_seguimiento=planned + timedelta(hours=2) if status == "retrasada" else None,
            motivo_retraso="Generada como retrasada para tension operativa" if status == "retrasada" else None,
        )
    )
    return 1


def _resolve_alert(db: Session, rng: random.Random) -> int:
    alert = db.scalar(
        select(CoreAlert)
        .where(CoreAlert.estado == "pendiente")
        .order_by(CoreAlert.fecha_creacion)
    )
    if alert is None or rng.random() > 0.75:
        return 0

    alert.estado = rng.choice(["revisada", "resuelta"])
    alert.revisada = True
    alert.fecha_revision = utc_now().replace(tzinfo=None)
    alert.notas_operario = "Actualizada por simulacion operativa."
    alert.accion_tomada = "Seguimiento realizado" if alert.estado == "resuelta" else None
    return 1


def _create_alert_from_lactation(db: Session, rng: random.Random) -> int:
    lactations = db.scalars(
        select(CoreLactation)
        .where(CoreLactation.activa.is_(True), CoreLactation.rcs_promedio.is_not(None))
        .order_by(CoreLactation.rcs_promedio.desc())
        .limit(20)
    ).all()
    lactation = _pick(lactations, rng)
    if lactation is None:
        return 0

    duplicate = db.scalar(
        select(CoreAlert).where(
            CoreAlert.animal_id == lactation.animal_id,
            CoreAlert.tipo_alerta == "calidad_leche",
            CoreAlert.estado == "pendiente",
        )
    )
    if duplicate is not None:
        return 0

    rcs = lactation.rcs_promedio or 0
    severity = "critica" if rcs >= 420000 else "alta" if rcs >= 260000 else "media"
    db.add(
        CoreAlert(
            id=str(uuid4()),
            animal_id=lactation.animal_id,
            tipo_alerta="calidad_leche",
            severidad=severity,
            descripcion="RCS individual fuera del rango objetivo en el ultimo control.",
            recomendacion="Revisar ubre, muestra individual y rutina de ordeno.",
            estado="pendiente",
            confianza_prediccion=round(rng.uniform(0.68, 0.93), 2),
            requiere_escalacion=severity in {"alta", "critica"},
            fecha_creacion=utc_now().replace(tzinfo=None),
            revisada=False,
        )
    )
    return 1


def _resolve_incident(db: Session, rng: random.Random) -> int:
    incident = db.scalar(
        select(CoreIncident)
        .where(CoreIncident.estado.in_(["abierta", "en_proceso"]))
        .order_by(CoreIncident.fecha_creacion)
    )
    if incident is None or rng.random() > 0.65:
        return 0

    incident.estado = rng.choice(["resuelta", "cerrada"])
    incident.fecha_resolucion = utc_now().replace(tzinfo=None)
    incident.resolucion = "Cerrada por simulacion tras revision operativa."
    return 1


def _create_incident(db: Session, rng: random.Random) -> int:
    zones = db.scalars(select(CoreZone).where(CoreZone.activa.is_(True))).all()
    animals = db.scalars(select(CoreAnimal).where(CoreAnimal.estado != "baja")).all()
    zone = _pick(zones, rng)
    if zone is None:
        return 0

    animal = _pick(animals, rng) if rng.random() < 0.55 else None
    db.add(
        CoreIncident(
            id=str(uuid4()),
            tipo=rng.choice(INCIDENT_TYPES),
            zona_id=zone.id,
            animal_id=animal.id if animal else None,
            descripcion="Incidencia generada por simulacion para mantener actividad operativa.",
            prioridad=rng.choice(["baja", "media", "media", "alta", "critica"]),
            estado=rng.choice(["abierta", "abierta", "en_proceso"]),
            fecha_creacion=utc_now().replace(tzinfo=None),
            reportado_por="Simulador",
        )
    )
    return 1


def _update_lactations(db: Session, rng: random.Random) -> int:
    lactations = db.scalars(select(CoreLactation).where(CoreLactation.activa.is_(True)).limit(8)).all()
    updated = 0
    for lactation in rng.sample(lactations, k=min(len(lactations), rng.randint(1, 3))):
        if lactation.produccion_promedio is not None:
            lactation.produccion_promedio = round(max(10, lactation.produccion_promedio + rng.uniform(-0.9, 0.9)), 1)
            if lactation.dias_transcurridos:
                lactation.produccion_total = round(lactation.produccion_promedio * lactation.dias_transcurridos, 1)
        if lactation.rcs_promedio is not None:
            lactation.rcs_promedio = max(50000, round(lactation.rcs_promedio + rng.randint(-18000, 22000)))
        if lactation.grasa_promedio is not None:
            lactation.grasa_promedio = round(min(4.8, max(3.1, lactation.grasa_promedio + rng.uniform(-0.04, 0.04))), 2)
        if lactation.proteina_promedio is not None:
            lactation.proteina_promedio = round(min(3.9, max(2.9, lactation.proteina_promedio + rng.uniform(-0.03, 0.03))), 2)
        updated += 1
    return updated


def _update_machinery(db: Session, rng: random.Random) -> int:
    machine = _pick(db.scalars(select(CoreMachinery)).all(), rng)
    if machine is None or rng.random() > 0.45:
        return 0

    if machine.estado in {"revision", "averia"}:
        machine.estado = "operativa"
        machine.observaciones = "Revision cerrada por simulacion."
    else:
        machine.estado = rng.choice(["operativa", "revision_programada", "revision"])
        machine.observaciones = "Estado actualizado por simulacion operativa."
    return 1


def _trim_operational_history(db: Session, caps: SimulationCaps) -> int:
    deleted = 0
    deleted += _delete_over_cap(
        db,
        CoreTask,
        caps.max_tasks,
        CoreTask.estado.in_(["ejecutada", "cancelada"]),
        CoreTask.fecha_programada,
    )
    deleted += _delete_over_cap(
        db,
        CoreAlert,
        caps.max_alerts,
        CoreAlert.estado.in_(["revisada", "resuelta", "falsa_alarma"]),
        CoreAlert.fecha_creacion,
    )
    deleted += _delete_over_cap(
        db,
        CoreIncident,
        caps.max_incidents,
        CoreIncident.estado.in_(["resuelta", "cerrada"]),
        CoreIncident.fecha_creacion,
    )
    return deleted


def _delete_over_cap(db: Session, model: type[Any], cap: int, condition: Any, order_column: Any) -> int:
    total = db.scalar(select(func.count()).select_from(model)) or 0
    overflow = max(0, total - cap)
    if overflow == 0:
        return 0

    candidates = db.scalars(
        select(model)
        .where(condition)
        .order_by(order_column)
        .limit(overflow)
    ).all()
    for item in candidates:
        db.delete(item)
    return len(candidates)


def _pick(items: list[Any], rng: random.Random) -> Any | None:
    return rng.choice(items) if items else None
