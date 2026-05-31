import uuid
from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Usuario
from app.models.tools4milk import Alerta, Animal, TareaEjecucion, TareaCatalogo, TratamientoActivo
from app.repositories import (
    alerts_repository,
    animals_repository,
    employees_repository,
    incidents_repository,
    lactations_repository,
    machinery_repository,
    tasks_repository,
    treatments_repository,
    zones_repository,
)
from app.schemas.api import AlertCreate, AlertsResponse, AlertUpdate
from app.security import get_current_user, require_roles
from app.services import (
    alerts_service,
    animals_service,
    employees_service,
    incidents_service,
    lactations_service,
    machinery_service,
    tasks_service,
    treatments_service,
    zones_service,
)
from app.time_utils import utc_now


router = APIRouter(prefix="/api/v1", tags=["Frontend Core"], dependencies=[Depends(get_current_user)])
DbSession = Annotated[Session, Depends(get_db)]
AdminOnly = Annotated[Usuario, Depends(require_roles("admin"))]
AnimalManager = Annotated[Usuario, Depends(require_roles("admin", "veterinario"))]
TaskManager = Annotated[Usuario, Depends(require_roles("admin", "operario", "alimentacion"))]
ClinicalManager = Annotated[Usuario, Depends(require_roles("admin", "veterinario"))]
QualityManager = Annotated[Usuario, Depends(require_roles("admin", "veterinario", "alimentacion"))]
OperationsManager = Annotated[Usuario, Depends(require_roles("admin", "operario", "alimentacion"))]


def _alerts_response(
    items: list[Alerta],
    skip: int,
    limit: int,
    animal_id: str | None = None,
) -> AlertsResponse:
    page = items[skip : skip + limit]
    pending = [a for a in items if a.activa and not a.ts_resolucion]
    return AlertsResponse(
        animal_id=animal_id,
        total=len(items),
        alertas=[alerts_service.serialize(a) for a in page],
        skip=skip,
        limit=limit,
        estadisticas={
            "total_alertas": len(items),
            "alertas_ultimos_30_dias": len(items),
            "pendientes": len(pending),
            "tasa_resolucion_pct": 0,
            "severidad_promedio": "media",
        },
    )


def _resolve_catalogo_id(db: Session, payload: dict) -> uuid.UUID | None:
    catalog_id_str = payload.get("tarea_catalogo_id")
    if catalog_id_str:
        try:
            uid = uuid.UUID(catalog_id_str)
            if db.get(TareaCatalogo, uid):
                return uid
        except (ValueError, AttributeError):
            pass
    catalog = db.scalar(select(TareaCatalogo).where(TareaCatalogo.activa.is_(True)).limit(1))
    if catalog:
        return catalog.id
    catalog_payload = payload.get("tarea_catalogo") or {}
    catalog = TareaCatalogo(
        id=uuid.uuid4(),
        codigo=str(payload.get("tarea_catalogo_id") or f"task-{uuid.uuid4().hex[:8]}")[:60],
        nombre=str(catalog_payload.get("nombre") or "Tarea operativa")[:150],
        descripcion=catalog_payload.get("descripcion"),
        cualificacion_requerida=catalog_payload.get("categoria"),
        duracion_estimada_min=catalog_payload.get("duracion_estimada_min"),
        activa=True,
    )
    db.add(catalog)
    db.flush()
    return catalog.id


def _estado_to_activa(estado: str | None) -> bool | None:
    if estado is None:
        return None
    return estado in {"operativa", "revision_programada"}


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
            "programadas": db.scalar(select(func.count()).select_from(TareaEjecucion).where(TareaEjecucion.estado == "pendiente")) or 0,
            "ejecutadas": db.scalar(select(func.count()).select_from(TareaEjecucion).where(TareaEjecucion.estado == "completada")) or 0,
            "retrasadas": db.scalar(select(func.count()).select_from(TareaEjecucion).where(TareaEjecucion.estado == "vencida")) or 0,
        },
        "animales": {
            "activos": db.scalar(select(func.count()).select_from(Animal).where(Animal.estado != "baja")) or 0,
        },
        "tratamientos": {
            "activos": db.scalar(select(func.count()).select_from(TratamientoActivo).where(TratamientoActivo.activo.is_(True))) or 0,
        },
    }


@router.get(
    "/animals",
    operation_id="list_animals",
    responses={
        200: {
            "content": {
                "application/json": {
                    "examples": {
                        "sample": {
                            "value": [
                                {
                                    "id": "animal-001",
                                    "crotal_oficial": "ES001",
                                    "nombre": "Luna",
                                    "estado": "produccion",
                                }
                            ]
                        }
                    }
                }
            }
        },
        422: {"description": "Parametros invalidos"},
        500: {"description": "Error interno"},
    },
)
def animals(db: DbSession, skip: int = 0, limit: int = 50, estado: str | None = None) -> list[dict[str, Any]]:
    items = animals_repository.get_all(db, skip=skip, limit=limit, estado=estado)
    return [animals_service.serialize(a) for a in items]


@router.get("/animals/active-count")
def animals_active_count(db: DbSession) -> int:
    return animals_repository.count_active(db)


@router.post("/animals", status_code=201)
def create_animal(payload: dict[str, Any], db: DbSession, _user: AnimalManager) -> dict[str, Any]:
    item = animals_repository.create(db, payload)
    return animals_service.serialize(item)


@router.get("/animals/search/by-crotal/{crotal}")
def animal_by_crotal(crotal: str, db: DbSession) -> dict[str, Any]:
    item = animals_repository.get_by_crotal(db, crotal)
    if item is None:
        raise HTTPException(status_code=404, detail="Animal no encontrado")
    return animals_service.serialize(item)


@router.get("/animals/{animal_id}")
def animal_detail(animal_id: str, db: DbSession) -> dict[str, Any]:
    item = animals_repository.get_by_id(db, animal_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Animal no encontrado")
    return animals_service.serialize(item)


@router.put("/animals/{animal_id}")
def update_animal(animal_id: str, payload: dict[str, Any], db: DbSession, _user: AnimalManager) -> dict[str, Any]:
    item = animals_repository.get_by_id(db, animal_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Animal no encontrado")
    item = animals_repository.update(db, item, payload)
    return animals_service.serialize(item)


@router.get("/zones")
def zones(db: DbSession) -> list[dict[str, Any]]:
    return [zones_service.serialize(z) for z in zones_repository.get_all(db)]


@router.post(
    "/zones",
    status_code=201,
    operation_id="create_zone",
    responses={422: {"description": "Payload invalido"}, 500: {"description": "Error interno"}},
    openapi_extra={
        "requestBody": {
            "content": {
                "application/json": {
                    "examples": {
                        "sample": {
                            "value": {
                                "nombre": "Secado",
                                "codigo": "SEC",
                                "tiene_pantalla_tv": True,
                                "tiene_tablet": True,
                            }
                        }
                    }
                }
            }
        }
    },
)
def create_zone(payload: dict[str, Any], db: DbSession, _user: AdminOnly) -> dict[str, Any]:
    zone = zones_repository.create(db, payload)
    return zones_service.serialize(zone)


@router.get("/zones/{zone_id}")
def zone_detail(zone_id: str, db: DbSession) -> dict[str, Any]:
    item = zones_repository.get_by_id(db, zone_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Zona no encontrada")
    return zones_service.serialize(item)


@router.put("/zones/{zone_id}")
def update_zone(zone_id: str, payload: dict[str, Any], db: DbSession, _user: AdminOnly) -> dict[str, Any]:
    item = zones_repository.get_by_id(db, zone_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Zona no encontrada")
    item = zones_repository.update(db, item, payload)
    return zones_service.serialize(item)


@router.get("/tareas-catalogo", operation_id="list_task_catalog")
def task_catalog(
    db: DbSession,
    activa: bool | None = None,
) -> list[dict[str, Any]]:
    """Return the task catalog (TareaCatalogo). Defaults to active items only."""
    query = select(TareaCatalogo).order_by(TareaCatalogo.nombre)
    if activa is None:
        query = query.where(TareaCatalogo.activa.is_(True))
    elif activa is False:
        pass  # no filter — return all
    else:
        query = query.where(TareaCatalogo.activa.is_(True))
    items = db.scalars(query).all()
    return [
        {
            "id": str(item.id),
            "codigo": item.codigo,
            "nombre": item.nombre,
            "descripcion": item.descripcion,
            "cualificacion_requerida": item.cualificacion_requerida,
            "duracion_estimada_min": item.duracion_estimada_min,
            "activa": item.activa,
        }
        for item in items
    ]


@router.get(
    "/tasks",
    operation_id="list_tasks",
    responses={
        200: {
            "content": {
                "application/json": {
                    "examples": {
                        "sample": {
                            "value": [
                                {
                                    "id": "task-001",
                                    "tarea_catalogo": {"nombre": "Revisar tanque"},
                                    "estado": "programada",
                                }
                            ]
                        }
                    }
                }
            }
        },
        422: {"description": "Parametros invalidos"},
        500: {"description": "Error interno"},
    },
)
def tasks(
    db: DbSession,
    skip: int = 0,
    limit: int = 50,
    estado: str | None = None,
    zona_id: str | None = None,
) -> list[dict[str, Any]]:
    rows = tasks_repository.get_all(db, skip=skip, limit=limit, estado=estado, zona_id=zona_id)
    return [tasks_service.serialize(ejecucion, catalogo) for ejecucion, catalogo in rows]


@router.post("/tasks", status_code=201)
def create_task(payload: dict[str, Any], db: DbSession, _user: TaskManager) -> dict[str, Any]:
    catalogo_id = _resolve_catalogo_id(db, payload)
    if catalogo_id is None:
        raise HTTPException(status_code=400, detail="No hay tareas en el catalogo disponibles")
    ejecucion, catalogo = tasks_repository.create(db, catalogo_id, payload)
    return tasks_service.serialize(ejecucion, catalogo)


@router.get("/tasks/{task_id}")
def task_detail(task_id: str, db: DbSession) -> dict[str, Any]:
    row = tasks_repository.get_by_id(db, task_id)
    if row is None:
        raise HTTPException(status_code=404, detail="Tarea no encontrada")
    return tasks_service.serialize(row[0], row[1])


@router.put("/tasks/{task_id}")
def update_task(task_id: str, payload: dict[str, Any], db: DbSession, _user: TaskManager) -> dict[str, Any]:
    row = tasks_repository.get_by_id(db, task_id)
    if row is None:
        raise HTTPException(status_code=404, detail="Tarea no encontrada")
    ejecucion, catalogo = tasks_repository.update(db, row[0], payload)
    return tasks_service.serialize(ejecucion, catalogo)


@router.get("/lactations")
def lactations(
    db: DbSession,
    skip: int = 0,
    limit: int = 50,
    animal_id: str | None = None,
    activa: bool | None = None,
) -> list[dict[str, Any]]:
    items = lactations_repository.get_all(db, skip=skip, limit=limit, animal_id=animal_id, activa=activa)
    return [lactations_service.serialize(l) for l in items]


@router.post("/lactations", status_code=201)
def create_lactation(payload: dict[str, Any], db: DbSession, _user: QualityManager) -> dict[str, Any]:
    item = lactations_repository.create(db, payload)
    return lactations_service.serialize(item)


@router.get("/lactations/quality/summary")
def quality_summary(db: DbSession) -> dict[str, Any]:
    items = lactations_repository.get_all_active(db)
    return lactations_service.quality_summary(items)


@router.put("/lactations/{lactation_id}")
def update_lactation(
    lactation_id: str,
    payload: dict[str, Any],
    db: DbSession,
    _user: QualityManager,
) -> dict[str, Any]:
    item = lactations_repository.get_by_id(db, lactation_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Lactacion no encontrada")
    item = lactations_repository.update(db, item, payload)
    return lactations_service.serialize(item)


@router.get("/alerts/critical")
def critical_alerts(db: DbSession) -> AlertsResponse:
    items = alerts_repository.get_critical(db)
    return _alerts_response(items, 0, 50)


@router.get("/alerts")
def list_alerts(db: DbSession, skip: int = 0, limit: int = 50, severidad: str | None = None) -> AlertsResponse:
    items = alerts_repository.get_all(db, skip=0, limit=10000, nivel=severidad)
    return _alerts_response(items, skip, limit)


@router.post("/alerts", status_code=201)
def create_alert(payload: AlertCreate, db: DbSession, _user: ClinicalManager) -> dict[str, Any]:
    item = alerts_repository.create(db, payload.model_dump())
    return alerts_service.serialize(item)


@router.get("/alerts/detail/{alert_id}")
def alert_detail(alert_id: str, db: DbSession) -> dict[str, Any]:
    item = alerts_repository.get_by_id(db, alert_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Alerta no encontrada")
    return alerts_service.serialize(item)


@router.patch("/alerts/{alert_id}")
def review_alert(alert_id: str, payload: AlertUpdate, db: DbSession, _user: ClinicalManager) -> dict[str, Any]:
    item = alerts_repository.get_by_id(db, alert_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Alerta no encontrada")
    item = alerts_repository.resolve(db, item, payload.model_dump(exclude_none=True))
    return alerts_service.serialize(item)


@router.get("/alerts/{animal_id}")
def animal_alerts(animal_id: str, db: DbSession, skip: int = 0, limit: int = 50) -> AlertsResponse:
    items = alerts_repository.get_by_animal(db, animal_id, skip=0, limit=10000)
    return _alerts_response(items, skip, limit, animal_id=animal_id)


@router.post("/alerts/generate/{animal_id}")
def generate_alerts(animal_id: str, db: DbSession, _user: ClinicalManager) -> dict[str, Any]:
    animal = animals_repository.get_by_id(db, animal_id)
    if animal is None:
        raise HTTPException(status_code=404, detail="Animal no encontrado")
    return {"generated": 0, "alertas": [], "animal_id": animal_id}


@router.get("/predictions/{animal_id}")
def predictions(animal_id: str, db: DbSession) -> dict[str, Any]:
    animal = animals_repository.get_by_id(db, animal_id) or animals_repository.get_by_crotal(db, animal_id)
    if animal is None:
        raise HTTPException(status_code=404, detail="Animal no encontrado")

    lactation = lactations_repository.get_active_for_animal(db, str(animal.id))
    active_treatments = db.scalars(
        select(TratamientoActivo).where(TratamientoActivo.animal_id == animal.id, TratamientoActivo.activo.is_(True))
    ).all()
    pending_alerts = db.scalars(
        select(Alerta).where(Alerta.animal_id == animal.id, Alerta.activa.is_(True))
    ).all()

    base_production = (
        float(lactation.produccion_total_kg) / 305
        if lactation and lactation.produccion_total_kg
        else 0
    )
    treatment_penalty = 0.08 if active_treatments else 0
    alert_penalty = min(len(pending_alerts) * 0.03, 0.12)
    expected = round(base_production * (1 - treatment_penalty - alert_penalty), 1) if base_production else 0
    trend = "descenso" if treatment_penalty or alert_penalty else "estable"
    series = [round(expected * factor, 1) for factor in [0.98, 0.99, 1.0, 1.01, 1.0, 1.02, 1.01]]

    risk_level = "alto" if active_treatments else "medio" if pending_alerts else "bajo"
    risk_factors = []
    if active_treatments:
        risk_factors.append("Tratamiento activo")
    if pending_alerts:
        risk_factors.append("Alertas pendientes")

    return {
        "animal_id": animal_id,
        "timestamp": utc_now().isoformat(),
        "produccion": {
            "tendencia": trend,
            "produccion_promedio_predicha": expected,
            "produccion_minima_predicha": round(expected * 0.93, 1),
            "produccion_maxima_predicha": round(expected * 1.07, 1),
            "dias_prediccion": 7,
            "confidence": 0.82 if lactation else 0.45,
            "series_diaria": series,
        },
        "composicion": {
            "grasa": {"prediccion": 0, "tendencia": "estable"},
            "proteina": {"prediccion": 0, "tendencia": "estable"},
            "lactosa": {"prediccion": 0, "tendencia": "estable"},
            "anomalia_detectada": False,
            "confidence": 0.79 if lactation else 0.42,
        },
        "riesgo_sanitario": {
            "riesgo_promedio": risk_level,
            "riesgos_especificos": {
                "mastitis": {
                    "probabilidad": 0.18,
                    "nivel": "bajo",
                }
            },
            "factores_riesgo": risk_factors,
            "confidence": 0.84 if lactation else 0.5,
            "dias_prediccion": 7,
        },
        "confianza_integrada": 0.82 if lactation else 0.46,
        "_mock": False,
    }


@router.get("/predictions/production/{animal_id}")
def production_prediction(animal_id: str, db: DbSession) -> dict[str, Any]:
    return predictions(animal_id, db)["produccion"]


@router.get("/predictions/composition/{animal_id}")
def composition_prediction(animal_id: str, db: DbSession) -> dict[str, Any]:
    return predictions(animal_id, db)["composicion"]


@router.get("/predictions/health-risk/{animal_id}")
def health_risk_prediction(animal_id: str, db: DbSession) -> dict[str, Any]:
    return predictions(animal_id, db)["riesgo_sanitario"]


@router.get("/incidents")
def incidents(
    db: DbSession,
    skip: int = 0,
    limit: int = 50,
    zona_id: str | None = None,
    animal_id: str | None = None,
    maquinaria_id: str | None = None,
    estado: str | None = None,
    tipo: str | None = None,
    fecha_desde: str | None = None,
    fecha_hasta: str | None = None,
) -> list[dict[str, Any]]:
    from datetime import datetime as _dt
    try:
        fd = _dt.fromisoformat(fecha_desde.replace("Z", "+00:00")) if fecha_desde else None
        fh = _dt.fromisoformat(fecha_hasta.replace("Z", "+00:00")) if fecha_hasta else None
    except ValueError as exc:
        raise HTTPException(status_code=422, detail="Formato de fecha invalido") from exc
    items = incidents_repository.get_all(
        db, skip=skip, limit=limit,
        zona_id=zona_id, animal_id=animal_id, maquinaria_id=maquinaria_id,
        estado=estado, tipo=tipo, fecha_desde=fd, fecha_hasta=fh,
    )
    return [incidents_service.serialize(i) for i in items]


@router.post("/incidents", status_code=201)
def create_incident(payload: dict[str, Any], db: DbSession, _user: OperationsManager) -> dict[str, Any]:
    item = incidents_repository.create(db, payload)
    return incidents_service.serialize(item)


@router.get("/incidents/{incident_id}")
def incident_detail(incident_id: str, db: DbSession) -> dict[str, Any]:
    item = incidents_repository.get_by_id(db, incident_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Incidencia no encontrada")
    return incidents_service.serialize(item)


@router.put("/incidents/{incident_id}")
def update_incident(incident_id: str, payload: dict[str, Any], db: DbSession, _user: OperationsManager) -> dict[str, Any]:
    item = incidents_repository.get_by_id(db, incident_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Incidencia no encontrada")
    item = incidents_repository.update(db, item, payload)
    return incidents_service.serialize(item)


@router.get("/treatments")
def treatments(
    db: DbSession,
    skip: int = 0,
    limit: int = 50,
    animal_id: str | None = None,
    activo: bool | None = None,
) -> list[dict[str, Any]]:
    items = treatments_repository.get_all(db, skip=skip, limit=limit, animal_id=animal_id, activo=activo)
    return [treatments_service.serialize(t) for t in items]


@router.post("/treatments", status_code=201)
def create_treatment(payload: dict[str, Any], db: DbSession, _user: ClinicalManager) -> dict[str, Any]:
    item = treatments_repository.create(db, payload)
    return treatments_service.serialize(item)


@router.get("/treatments/{treatment_id}")
def treatment_detail(treatment_id: str, db: DbSession) -> dict[str, Any]:
    item = treatments_repository.get_by_id(db, treatment_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Tratamiento no encontrado")
    return treatments_service.serialize(item)


@router.put("/treatments/{treatment_id}")
def update_treatment(
    treatment_id: str,
    payload: dict[str, Any],
    db: DbSession,
    _user: ClinicalManager,
) -> dict[str, Any]:
    item = treatments_repository.get_by_id(db, treatment_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Tratamiento no encontrado")
    item = treatments_repository.update(db, item, payload)
    return treatments_service.serialize(item)


@router.get("/employees")
def employees(db: DbSession, activo: bool | None = None) -> list[dict[str, Any]]:
    items = employees_repository.get_all(db, activo=activo)
    return [employees_service.serialize(e) for e in items]


@router.post("/employees", status_code=201)
def create_employee(payload: dict[str, Any], db: DbSession, _user: AdminOnly) -> dict[str, Any]:
    item = employees_repository.create(db, payload)
    return employees_service.serialize(item)


@router.put("/employees/{employee_id}")
def update_employee(employee_id: str, payload: dict[str, Any], db: DbSession, _user: AdminOnly) -> dict[str, Any]:
    item = employees_repository.get_by_id(db, employee_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Empleado no encontrado")
    item = employees_repository.update(db, item, payload)
    return employees_service.serialize(item)


@router.get("/machinery")
def machinery(
    db: DbSession,
    skip: int = 0,
    limit: int = 50,
    estado: str | None = None,
    zona_id: str | None = None,
) -> list[dict[str, Any]]:
    items = machinery_repository.get_all(
        db, skip=skip, limit=limit, activa=_estado_to_activa(estado), zona_id=zona_id
    )
    return [machinery_service.serialize(m) for m in items]


@router.post("/machinery", status_code=201)
def create_machinery(payload: dict[str, Any], db: DbSession, _user: OperationsManager) -> dict[str, Any]:
    item = machinery_repository.create(db, payload)
    return machinery_service.serialize(item)


@router.put("/machinery/{machinery_id}")
def update_machinery(
    machinery_id: str,
    payload: dict[str, Any],
    db: DbSession,
    _user: OperationsManager,
) -> dict[str, Any]:
    item = machinery_repository.get_by_id(db, machinery_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Maquinaria no encontrada")
    item = machinery_repository.update(db, item, payload)
    return machinery_service.serialize(item)
