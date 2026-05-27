from __future__ import annotations

import re
import unicodedata
from datetime import date
from typing import Any
from uuid import uuid4

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import (
    CoreAlert,
    CoreAnimal,
    CoreIncident,
    CoreLactation,
    CoreTask,
    CoreTreatment,
    CoreZone,
    Usuario,
)
from app.services.frontend_seed import ensure_frontend_seed_data
from app.time_utils import utc_now


WRITE_PERMISSIONS = {
    "create_lactation": {"admin", "veterinario", "alimentacion"},
    "create_treatment": {"admin", "veterinario"},
    "create_task": {"admin", "operario", "alimentacion"},
    "complete_task": {"admin", "operario", "alimentacion"},
    "update_alert": {"admin", "veterinario"},
    "create_incident": {"admin", "operario", "alimentacion"},
}


def handle_assistant_message(
    db: Session,
    user: Usuario,
    message: str,
    confirmed: bool = False,
    draft: dict[str, Any] | None = None,
) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    if confirmed and draft:
        return _execute_draft(db, user, draft)

    text = _normalize(message)
    if _is_forbidden_creation(text):
        return _response(
            "No puedo crear animales, empleados, maquinaria ni zonas. Si quieres, puedo crear lactaciones, tratamientos, tareas o incidencias.",
            action="forbidden",
        )

    if "estado" in text or "resumen" in text or "como va" in text or "consulta" in text:
        return _status_response(db)
    if "alerta" in text and any(word in text for word in ["resolver", "resuelta", "revisar", "revisada", "eliminar", "quitar"]):
        return _prepare_alert_update(db, text)
    if "incidencia" in text or "incidente" in text:
        return _prepare_incident(db, text, message)
    if "tarea" in text and any(word in text for word in ["completar", "completa", "hecha", "ejecutar", "ejecutada"]):
        return _prepare_complete_task(db, text)
    if "tarea" in text and any(word in text for word in ["crear", "crea", "programa", "programar", "nueva"]):
        return _prepare_task(db, text, message)
    if "tratamiento" in text:
        return _prepare_treatment(db, text, message)
    if "lactacion" in text or "lactancia" in text:
        return _prepare_lactation(db, text)
    if "alerta" in text:
        return _status_response(db, focus="alerts")
    if "produccion" in text or "calidad" in text:
        return _status_response(db, focus="quality")

    return _response(
        "Puedo consultar estado, crear lactaciones, tratamientos, tareas e incidencias, y revisar o resolver alertas. Dime la accion con el animal, zona o identificador si lo tienes.",
        action="help",
    )


def _execute_draft(db: Session, user: Usuario, draft: dict[str, Any]) -> dict[str, Any]:
    action = str(draft.get("action") or "")
    _require_role(user, action)

    if action == "create_incident":
        item = CoreIncident(
            id=str(uuid4()),
            tipo=str(draft["tipo"]),
            zona_id=str(draft["zona_id"]),
            animal_id=draft.get("animal_id"),
            descripcion=str(draft["descripcion"]),
            prioridad=str(draft["prioridad"]),
            estado="abierta",
            fecha_creacion=utc_now().replace(tzinfo=None),
            reportado_por=user.username,
        )
        db.add(item)
        db.commit()
        return _done("Incidencia creada.", action, {"id": item.id})

    if action == "create_task":
        task_id = str(uuid4())
        item = CoreTask(
            id=task_id,
            tarea_catalogo_id=f"assistant-{task_id[:8]}",
            tarea_catalogo={
                "id": f"assistant-{task_id[:8]}",
                "nombre": str(draft["nombre"]),
                "categoria": str(draft.get("categoria") or "operativa"),
                "frecuencia": "puntual",
                "zona_aplicable": draft["zona_id"],
            },
            zona_id=str(draft["zona_id"]),
            fecha_programada=utc_now().replace(tzinfo=None),
            estado="programada",
            checklist_completado="false",
            es_urgente=bool(draft.get("es_urgente", False)),
            observaciones="Creada por asistente operativo.",
            requiere_seguimiento=False,
        )
        db.add(item)
        db.commit()
        return _done("Tarea creada.", action, {"id": item.id})

    if action == "complete_task":
        item = db.get(CoreTask, str(draft["task_id"]))
        if item is None:
            raise HTTPException(status_code=404, detail="Tarea no encontrada")
        item.estado = "ejecutada"
        item.fecha_ejecucion = utc_now().replace(tzinfo=None)
        item.ejecutado_por = user.username
        item.resultado = "ok"
        item.checklist_completado = "true"
        item.requiere_seguimiento = False
        db.commit()
        return _done("Tarea completada.", action, {"id": item.id})

    if action == "update_alert":
        item = db.get(CoreAlert, str(draft["alert_id"]))
        if item is None:
            raise HTTPException(status_code=404, detail="Alerta no encontrada")
        item.estado = str(draft["estado"])
        item.revisada = True
        item.fecha_revision = utc_now().replace(tzinfo=None)
        item.notas_operario = "Actualizada por asistente operativo."
        db.commit()
        return _done("Alerta actualizada.", action, {"id": item.id, "estado": item.estado})

    if action == "create_treatment":
        item = CoreTreatment(
            id=str(uuid4()),
            animal_id=str(draft["animal_id"]),
            medicamento=str(draft["medicamento"]),
            dosis=str(draft["dosis"]),
            via_administracion=draft.get("via_administracion") or "no especificada",
            fecha_inicio=str(draft.get("fecha_inicio") or date.today().isoformat()),
            activo=True,
            motivo=draft.get("motivo"),
            veterinario=user.username,
            observaciones="Creado por asistente operativo.",
        )
        db.add(item)
        db.commit()
        return _done("Tratamiento creado.", action, {"id": item.id})

    if action == "create_lactation":
        production = float(draft.get("produccion_promedio") or 0)
        days = int(draft.get("dias_transcurridos") or 1)
        item = CoreLactation(
            id=str(uuid4()),
            animal_id=str(draft["animal_id"]),
            numero_lactacion=draft.get("numero_lactacion"),
            fecha_inicio=str(draft.get("fecha_inicio") or date.today().isoformat()),
            dias_transcurridos=days,
            produccion_promedio=production or None,
            produccion_total=round(production * days, 1) if production else None,
            grasa_promedio=draft.get("grasa_promedio"),
            proteina_promedio=draft.get("proteina_promedio"),
            rcs_promedio=draft.get("rcs_promedio"),
            activa=True,
        )
        db.add(item)
        db.commit()
        return _done("Lactacion creada.", action, {"id": item.id})

    return _response("No reconozco el borrador de accion.", action="unknown")


def _prepare_incident(db: Session, text: str, original: str) -> dict[str, Any]:
    zone = _find_zone(db, text)
    animal = _find_animal(db, text)
    description = _description_after(original, ["porque", "por", "incidencia"]) or original.strip()
    priority = _priority(text)
    missing = []
    if zone is None:
        missing.append("zona")
    if len(description) < 8:
        missing.append("descripcion")
    draft = {
        "action": "create_incident",
        "tipo": _incident_type(text),
        "zona_id": zone.id if zone else None,
        "animal_id": animal.id if animal else None,
        "descripcion": description,
        "prioridad": priority,
    }
    return _draft_response(
        "Voy a crear una incidencia operativa.",
        draft,
        missing,
        f"Crear incidencia {priority} en {zone.nombre if zone else 'zona pendiente'}: {description}",
    )


def _prepare_task(db: Session, text: str, original: str) -> dict[str, Any]:
    zone = _find_zone(db, text)
    name = _description_after(original, ["tarea", "programa", "crea"]) or original.strip()
    missing = []
    if zone is None:
        missing.append("zona")
    if len(name) < 5:
        missing.append("descripcion")
    draft = {
        "action": "create_task",
        "zona_id": zone.id if zone else None,
        "nombre": name[:120],
        "categoria": "alimentacion" if "racion" in text or "aliment" in text else "operativa",
        "es_urgente": any(word in text for word in ["urgente", "critica", "hoy"]),
    }
    return _draft_response(
        "Voy a crear una tarea.",
        draft,
        missing,
        f"Crear tarea en {zone.nombre if zone else 'zona pendiente'}: {name[:120]}",
    )


def _prepare_complete_task(db: Session, text: str) -> dict[str, Any]:
    task = _find_task(db, text)
    missing = [] if task else ["task_id"]
    draft = {"action": "complete_task", "task_id": task.id if task else None}
    return _draft_response(
        "Voy a completar una tarea.",
        draft,
        missing,
        f"Marcar como ejecutada la tarea {task.id if task else 'pendiente de identificar'}",
    )


def _prepare_alert_update(db: Session, text: str) -> dict[str, Any]:
    alert = _find_alert(db, text)
    missing = [] if alert else ["alert_id"]
    state = "falsa_alarma" if "falsa" in text else "revisada" if "revis" in text else "resuelta"
    if "eliminar" in text or "quitar" in text:
        state = "resuelta"
    draft = {"action": "update_alert", "alert_id": alert.id if alert else None, "estado": state}
    return _draft_response(
        "No elimino alertas fisicamente; puedo dejarlas revisadas, resueltas o como falsa alarma.",
        draft,
        missing,
        f"Actualizar alerta {alert.id if alert else 'pendiente de identificar'} a {state.replace('_', ' ')}",
    )


def _prepare_treatment(db: Session, text: str, original: str) -> dict[str, Any]:
    animal = _find_animal(db, text)
    medicine = _extract_after(text, ["medicamento", "con", "tratamiento"])
    dose = _extract_dose(original)
    missing = []
    if animal is None:
        missing.append("animal")
    if not medicine:
        missing.append("medicamento")
    if not dose:
        missing.append("dosis")
    draft = {
        "action": "create_treatment",
        "animal_id": animal.id if animal else None,
        "medicamento": medicine,
        "dosis": dose,
        "fecha_inicio": _extract_date(text) or date.today().isoformat(),
        "motivo": _description_after(original, ["motivo", "por"]),
    }
    return _draft_response(
        "Voy a crear un tratamiento.",
        draft,
        missing,
        f"Crear tratamiento para {animal.crotal_oficial if animal else 'animal pendiente'} con {medicine or 'medicamento pendiente'} y dosis {dose or 'pendiente'}",
    )


def _prepare_lactation(db: Session, text: str) -> dict[str, Any]:
    animal = _find_animal(db, text)
    production = _extract_number_before(text, ["l", "litro", "litros"])
    missing = []
    if animal is None:
        missing.append("animal")
    draft = {
        "action": "create_lactation",
        "animal_id": animal.id if animal else None,
        "fecha_inicio": _extract_date(text) or date.today().isoformat(),
        "dias_transcurridos": int(_extract_number_after(text, "dias") or 1),
        "produccion_promedio": production,
        "grasa_promedio": _extract_number_after(text, "grasa"),
        "proteina_promedio": _extract_number_after(text, "proteina"),
        "rcs_promedio": _extract_number_after(text, "rcs"),
    }
    return _draft_response(
        "Voy a crear una lactacion activa.",
        draft,
        missing,
        f"Crear lactacion para {animal.crotal_oficial if animal else 'animal pendiente'} con produccion {production or 'no indicada'} L/dia",
    )


def _status_response(db: Session, focus: str | None = None) -> dict[str, Any]:
    pending_alerts = db.scalar(select(func.count()).select_from(CoreAlert).where(CoreAlert.estado == "pendiente")) or 0
    critical_alerts = db.scalar(select(func.count()).select_from(CoreAlert).where(CoreAlert.estado == "pendiente", CoreAlert.severidad == "critica")) or 0
    delayed_tasks = db.scalar(select(func.count()).select_from(CoreTask).where(CoreTask.estado == "retrasada")) or 0
    open_incidents = db.scalar(select(func.count()).select_from(CoreIncident).where(CoreIncident.estado.in_(["abierta", "en_proceso"]))) or 0
    active_animals = db.scalar(select(func.count()).select_from(CoreAnimal).where(CoreAnimal.estado != "baja")) or 0
    avg_production = db.scalar(select(func.avg(CoreLactation.produccion_promedio)).where(CoreLactation.activa.is_(True)))
    result = {
        "pending_alerts": pending_alerts,
        "critical_alerts": critical_alerts,
        "delayed_tasks": delayed_tasks,
        "open_incidents": open_incidents,
        "active_animals": active_animals,
        "avg_production": round(float(avg_production), 1) if avg_production else None,
    }
    if focus == "alerts":
        reply = f"Hay {pending_alerts} alertas pendientes, {critical_alerts} criticas."
    elif focus == "quality":
        reply = f"La produccion media es {result['avg_production'] or 'N/D'} L/dia con {active_animals} animales activos."
    else:
        reply = (
            f"Estado actual: {pending_alerts} alertas pendientes, {delayed_tasks} tareas retrasadas, "
            f"{open_incidents} incidencias abiertas y produccion media de {result['avg_production'] or 'N/D'} L/dia."
        )
    return _response(reply, action="query_status", result=result)


def _draft_response(prefix: str, draft: dict[str, Any], missing: list[str], summary: str) -> dict[str, Any]:
    if missing:
        fields = ", ".join(missing)
        return _response(f"{prefix} Me faltan estos datos: {fields}.", action=str(draft["action"]), missing_fields=missing, draft=draft)
    return _response(f"{summary}. Confirmame para ejecutarlo.", action=str(draft["action"]), requires_confirmation=True, draft=draft)


def _done(reply: str, action: str, result: dict[str, Any]) -> dict[str, Any]:
    return _response(reply, action=action, result=result)


def _response(
    reply: str,
    action: str | None = None,
    requires_confirmation: bool = False,
    missing_fields: list[str] | None = None,
    draft: dict[str, Any] | None = None,
    result: dict[str, Any] | None = None,
) -> dict[str, Any]:
    return {
        "reply": reply,
        "action": action,
        "requires_confirmation": requires_confirmation,
        "missing_fields": missing_fields or [],
        "draft": draft,
        "result": result,
    }


def _require_role(user: Usuario, action: str) -> None:
    allowed = WRITE_PERMISSIONS.get(action)
    if allowed and user.role not in allowed:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes permisos para esta accion")


def _is_forbidden_creation(text: str) -> bool:
    if not any(word in text for word in ["crear", "crea", "alta", "nuevo", "nueva"]):
        return False
    forbidden_patterns = [
        r"\b(?:crear|crea|alta|nuevo|nueva)\s+(?:un\s+|una\s+)?animal\b",
        r"\b(?:crear|crea|alta|nuevo|nueva)\s+(?:un\s+|una\s+)?vaca\b",
        r"\b(?:crear|crea|alta|nuevo|nueva)\s+(?:un\s+|una\s+)?emplead[oa]\b",
        r"\b(?:crear|crea|alta|nuevo|nueva)\s+(?:un\s+|una\s+)?trabajador(?:a)?\b",
        r"\b(?:crear|crea|alta|nuevo|nueva)\s+(?:un\s+|una\s+)?maquin(?:a|aria)\b",
        r"\b(?:crear|crea|alta|nuevo|nueva)\s+(?:un\s+|una\s+)?zona\b",
    ]
    return any(re.search(pattern, text) for pattern in forbidden_patterns)


def _find_zone(db: Session, text: str) -> CoreZone | None:
    zones = db.scalars(select(CoreZone)).all()
    for zone in zones:
        if _normalize(zone.id) in text or _normalize(zone.codigo) in text or _normalize(zone.nombre) in text:
            return zone
    return None


def _find_animal(db: Session, text: str) -> CoreAnimal | None:
    match = re.search(r"\banimal-\d{3}\b", text)
    if match:
        item = db.get(CoreAnimal, match.group(0))
        if item:
            return item
    crotal = re.search(r"\bes\d{6,}\b", text)
    if crotal:
        item = db.scalar(select(CoreAnimal).where(func.lower(CoreAnimal.crotal_oficial) == crotal.group(0)))
        if item:
            return item
    animals = db.scalars(select(CoreAnimal).where(CoreAnimal.estado != "baja")).all()
    for animal in animals:
        if animal.nombre and _normalize(animal.nombre) in text:
            return animal
    return None


def _find_task(db: Session, text: str) -> CoreTask | None:
    match = re.search(r"\btask-\d{3}\b", text)
    if match:
        return db.get(CoreTask, match.group(0))
    if "primera" in text or "siguiente" in text or "pendiente" in text:
        return db.scalar(
            select(CoreTask)
            .where(CoreTask.estado.in_(["programada", "retrasada"]))
            .order_by(CoreTask.fecha_programada)
        )
    return None


def _find_alert(db: Session, text: str) -> CoreAlert | None:
    match = re.search(r"\balert-\d{3}\b", text)
    if match:
        return db.get(CoreAlert, match.group(0))
    severity = "critica" if "critica" in text else "alta" if "alta" in text else None
    query = select(CoreAlert).where(CoreAlert.estado == "pendiente").order_by(CoreAlert.fecha_creacion)
    if severity:
        query = query.where(CoreAlert.severidad == severity)
    return db.scalar(query)


def _priority(text: str) -> str:
    if "critica" in text or "urgente" in text:
        return "critica"
    if "alta" in text:
        return "alta"
    if "baja" in text:
        return "baja"
    return "media"


def _incident_type(text: str) -> str:
    if "robot" in text or "maquina" in text:
        return "Maquinaria - incidencia operativa"
    if "leche" in text or "calidad" in text:
        return "Calidad - parametro operativo"
    if "racion" in text or "aliment" in text:
        return "Alimentacion - ajuste operativo"
    if "animal" in text or "vaca" in text:
        return "Sanitaria - seguimiento animal"
    return "Operativa - revision"


def _normalize(value: str | None) -> str:
    if not value:
        return ""
    normalized = unicodedata.normalize("NFKD", value)
    ascii_text = normalized.encode("ascii", "ignore").decode("ascii")
    return re.sub(r"\s+", " ", ascii_text.lower()).strip()


def _description_after(original: str, markers: list[str]) -> str | None:
    normalized = _normalize(original)
    for marker in markers:
        index = normalized.find(marker)
        if index >= 0:
            return original[index + len(marker):].strip(" :,-.")
    return None


def _extract_after(text: str, markers: list[str]) -> str | None:
    for marker in markers:
        match = re.search(rf"{marker}\s+([a-z0-9\s\-]+)", text)
        if match:
            value = match.group(1).strip()
            return value[:80] if value else None
    return None


def _extract_dose(text: str) -> str | None:
    match = re.search(r"(\d+(?:[,.]\d+)?\s*(?:ml|mg|g|kg|comprimidos?|aplicaciones?))", _normalize(text))
    return match.group(1).replace(",", ".") if match else None


def _extract_date(text: str) -> str | None:
    match = re.search(r"\b(20\d{2}-\d{2}-\d{2})\b", text)
    return match.group(1) if match else None


def _extract_number_before(text: str, markers: list[str]) -> float | None:
    for marker in markers:
        match = re.search(rf"(\d+(?:[,.]\d+)?)\s*{marker}\b", text)
        if match:
            return float(match.group(1).replace(",", "."))
    return None


def _extract_number_after(text: str, marker: str) -> float | None:
    match = re.search(rf"{marker}\s*(?:de)?\s*(\d+(?:[,.]\d+)?)", text)
    return float(match.group(1).replace(",", ".")) if match else None
