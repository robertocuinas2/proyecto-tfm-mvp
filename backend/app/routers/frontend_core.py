from datetime import datetime
from typing import Annotated, Any
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import (
    CoreAlert,
    CoreAnimal,
    CoreEmployee,
    CoreIncident,
    CoreLactation,
    CoreMachinery,
    CoreTask,
    CoreTreatment,
    CoreZone,
    Usuario,
)
from app.schemas.api import AlertCreate, AlertsResponse, AlertUpdate
from app.security import get_current_user, require_roles
from app.services.frontend_seed import ensure_frontend_seed_data, parse_datetime
from app.time_utils import utc_now


router = APIRouter(prefix="/api/v1", tags=["Frontend Core"], dependencies=[Depends(get_current_user)])
DbSession = Annotated[Session, Depends(get_db)]
AdminOnly = Annotated[Usuario, Depends(require_roles("admin"))]
AnimalManager = Annotated[Usuario, Depends(require_roles("admin", "veterinario"))]
TaskManager = Annotated[Usuario, Depends(require_roles("admin", "operario", "alimentacion"))]
ClinicalManager = Annotated[Usuario, Depends(require_roles("admin", "veterinario"))]
QualityManager = Annotated[Usuario, Depends(require_roles("admin", "veterinario", "alimentacion"))]
OperationsManager = Annotated[Usuario, Depends(require_roles("admin", "operario", "alimentacion"))]


def dt(value: datetime | None) -> str | None:
    return value.isoformat() if value else None


def paginated(items: list[Any], skip: int, limit: int) -> list[Any]:
    return items[skip : skip + limit]


def serialize_animal(item: CoreAnimal) -> dict[str, Any]:
    return {
        "id": item.id,
        "crotal_oficial": item.crotal_oficial,
        "nombre": item.nombre,
        "sexo": item.sexo,
        "fecha_nacimiento": item.fecha_nacimiento,
        "raza": item.raza,
        "estado": item.estado,
        "estado_reproductivo": item.estado_reproductivo,
        "fecha_entrada": item.fecha_entrada,
        "fecha_baja": item.fecha_baja,
        "motivo_baja": item.motivo_baja,
        "notas": item.notas,
    }


def serialize_zone(item: CoreZone) -> dict[str, Any]:
    return {
        "id": item.id,
        "nombre": item.nombre,
        "codigo": item.codigo,
        "descripcion": item.descripcion,
        "tipo": item.tipo,
        "tiene_pantalla_tv": item.tiene_pantalla_tv,
        "tiene_tablet": item.tiene_tablet,
        "activa": item.activa,
    }


def serialize_task(item: CoreTask) -> dict[str, Any]:
    return {
        "id": item.id,
        "tarea_catalogo_id": item.tarea_catalogo_id,
        "tarea_catalogo": item.tarea_catalogo,
        "zona_id": item.zona_id,
        "fecha_programada": dt(item.fecha_programada),
        "fecha_ejecucion": dt(item.fecha_ejecucion),
        "estado": item.estado,
        "ejecutado_por": item.ejecutado_por,
        "tiempo_ejecucion_minutos": item.tiempo_ejecucion_minutos,
        "resultado": item.resultado,
        "observaciones": item.observaciones,
        "problemas_encontrados": item.problemas_encontrados,
        "acciones_correctivas": item.acciones_correctivas,
        "checklist_completado": item.checklist_completado,
        "checklist_datos": item.checklist_datos,
        "es_urgente": item.es_urgente,
        "motivo_retraso": item.motivo_retraso,
        "requiere_seguimiento": item.requiere_seguimiento,
        "fecha_seguimiento": dt(item.fecha_seguimiento),
    }


def serialize_alert(item: CoreAlert) -> dict[str, Any]:
    return {
        "id": item.id,
        "animal_id": item.animal_id,
        "tipo_alerta": item.tipo_alerta,
        "severidad": item.severidad,
        "descripcion": item.descripcion,
        "recomendacion": item.recomendacion,
        "estado": item.estado,
        "confianza_prediccion": item.confianza_prediccion,
        "requiere_escalacion": item.requiere_escalacion,
        "fecha_creacion": dt(item.fecha_creacion),
        "fecha_revision": dt(item.fecha_revision),
        "revisada": item.revisada,
        "notas_operario": item.notas_operario,
        "accion_tomada": item.accion_tomada,
        "veterinario_responsable": item.veterinario_responsable,
    }


def serialize_incident(item: CoreIncident) -> dict[str, Any]:
    return {
        "id": item.id,
        "tipo": item.tipo,
        "zona_id": item.zona_id,
        "animal_id": item.animal_id,
        "descripcion": item.descripcion,
        "prioridad": item.prioridad,
        "estado": item.estado,
        "fecha_creacion": dt(item.fecha_creacion),
        "fecha_resolucion": dt(item.fecha_resolucion),
        "resolucion": item.resolucion,
        "reportado_por": item.reportado_por,
    }


def serialize_lactation(item: CoreLactation) -> dict[str, Any]:
    return {
        "id": item.id,
        "animal_id": item.animal_id,
        "numero_lactacion": item.numero_lactacion,
        "fecha_inicio": item.fecha_inicio,
        "fecha_fin": item.fecha_fin,
        "dias_transcurridos": item.dias_transcurridos,
        "produccion_promedio": item.produccion_promedio,
        "produccion_total": item.produccion_total,
        "grasa_promedio": item.grasa_promedio,
        "proteina_promedio": item.proteina_promedio,
        "rcs_promedio": item.rcs_promedio,
        "activa": item.activa,
    }


def serialize_treatment(item: CoreTreatment) -> dict[str, Any]:
    return {
        "id": item.id,
        "animal_id": item.animal_id,
        "medicamento": item.medicamento,
        "dosis": item.dosis,
        "via_administracion": item.via_administracion,
        "fecha_inicio": item.fecha_inicio,
        "fecha_fin": item.fecha_fin,
        "periodo_retirada_dias": item.periodo_retirada_dias,
        "fecha_fin_retirada": item.fecha_fin_retirada,
        "activo": item.activo,
        "motivo": item.motivo,
        "veterinario": item.veterinario,
        "observaciones": item.observaciones,
    }


def serialize_employee(item: CoreEmployee) -> dict[str, Any]:
    return {
        "id": item.id,
        "nombre": item.nombre,
        "apellidos": item.apellidos,
        "role": item.role,
        "zona_principal_id": item.zona_principal_id,
        "activo": item.activo,
    }


def serialize_machinery(item: CoreMachinery) -> dict[str, Any]:
    return {
        "id": item.id,
        "nombre": item.nombre,
        "tipo": item.tipo,
        "zona_id": item.zona_id,
        "estado": item.estado,
        "proxima_revision": item.proxima_revision,
        "observaciones": item.observaciones,
    }


def alerts_response(
    items: list[CoreAlert],
    skip: int,
    limit: int,
    animal_id: str | None = None,
) -> AlertsResponse:
    page = paginated(items, skip, limit)
    return AlertsResponse(
        animal_id=animal_id,
        total=len(items),
        alertas=[serialize_alert(item) for item in page],
        skip=skip,
        limit=limit,
        estadisticas={
            "total_alertas": len(items),
            "alertas_ultimos_30_dias": len(items),
            "pendientes": len([item for item in items if item.estado == "pendiente"]),
            "tasa_resolucion_pct": 0,
            "severidad_promedio": "media",
        },
    )


@router.get("/dashboard/summary")
def dashboard_summary(db: DbSession) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    pending_alerts = db.scalars(select(CoreAlert).where(CoreAlert.estado == "pendiente")).all()
    return {
        "alertas": {
            "total_pendientes": len(pending_alerts),
            "criticas": len([item for item in pending_alerts if item.severidad == "critica"]),
            "altas": len([item for item in pending_alerts if item.severidad == "alta"]),
        },
        "tareas": {
            "programadas": db.scalar(select(func.count()).select_from(CoreTask).where(CoreTask.estado == "programada")) or 0,
            "ejecutadas": db.scalar(select(func.count()).select_from(CoreTask).where(CoreTask.estado == "ejecutada")) or 0,
            "retrasadas": db.scalar(select(func.count()).select_from(CoreTask).where(CoreTask.estado == "retrasada")) or 0,
        },
        "animales": {
            "activos": db.scalar(select(func.count()).select_from(CoreAnimal).where(CoreAnimal.estado != "baja")) or 0,
        },
        "tratamientos": {
            "activos": db.scalar(select(func.count()).select_from(CoreTreatment).where(CoreTreatment.activo.is_(True))) or 0,
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
    ensure_frontend_seed_data(db)
    query = select(CoreAnimal).order_by(CoreAnimal.crotal_oficial)
    if estado is not None:
        query = query.where(CoreAnimal.estado == estado)
    return [serialize_animal(item) for item in db.scalars(query.offset(skip).limit(limit)).all()]


@router.get("/animals/active-count")
def animals_active_count(db: DbSession) -> int:
    ensure_frontend_seed_data(db)
    return db.scalar(select(func.count()).select_from(CoreAnimal).where(CoreAnimal.estado != "baja")) or 0


@router.post("/animals", status_code=201)
def create_animal(payload: dict[str, Any], db: DbSession, _user: AnimalManager) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = CoreAnimal(
        id=payload.get("id", str(uuid4())),
        crotal_oficial=payload["crotal_oficial"],
        nombre=payload.get("nombre"),
        sexo=payload.get("sexo", "hembra"),
        fecha_nacimiento=payload.get("fecha_nacimiento", utc_now().date().isoformat()),
        raza=payload.get("raza"),
        estado=payload.get("estado", "recria"),
        estado_reproductivo=payload.get("estado_reproductivo"),
        fecha_entrada=payload.get("fecha_entrada", utc_now().date().isoformat()),
        fecha_baja=payload.get("fecha_baja"),
        motivo_baja=payload.get("motivo_baja"),
        notas=payload.get("notas"),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return serialize_animal(item)


@router.get("/animals/search/by-crotal/{crotal}")
def animal_by_crotal(crotal: str, db: DbSession) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = db.scalar(select(CoreAnimal).where(CoreAnimal.crotal_oficial == crotal))
    if item is None:
        raise HTTPException(status_code=404, detail="Animal no encontrado")
    return serialize_animal(item)


@router.get("/animals/{animal_id}")
def animal_detail(animal_id: str, db: DbSession) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = db.get(CoreAnimal, animal_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Animal no encontrado")
    return serialize_animal(item)


@router.put("/animals/{animal_id}")
def update_animal(animal_id: str, payload: dict[str, Any], db: DbSession, _user: AnimalManager) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = db.get(CoreAnimal, animal_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Animal no encontrado")
    for key, value in payload.items():
        if hasattr(item, key):
            setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return serialize_animal(item)


@router.get("/zones")
def zones(db: DbSession) -> list[dict[str, Any]]:
    ensure_frontend_seed_data(db)
    return [serialize_zone(item) for item in db.scalars(select(CoreZone).order_by(CoreZone.codigo)).all()]


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
                                "id": "secado",
                                "nombre": "Secado",
                                "codigo": "SEC",
                                "tipo": "cuidados",
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
    ensure_frontend_seed_data(db)
    zone = CoreZone(
        id=payload.get("id", str(uuid4())),
        nombre=payload.get("nombre", "Nueva zona"),
        codigo=payload.get("codigo", "NEW"),
        descripcion=payload.get("descripcion"),
        tipo=payload.get("tipo", "operativa"),
        tiene_pantalla_tv=bool(payload.get("tiene_pantalla_tv", True)),
        tiene_tablet=bool(payload.get("tiene_tablet", True)),
        activa=bool(payload.get("activa", True)),
    )
    db.add(zone)
    db.commit()
    db.refresh(zone)
    return serialize_zone(zone)


@router.get("/zones/{zone_id}")
def zone_detail(zone_id: str, db: DbSession) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = db.get(CoreZone, zone_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Zona no encontrada")
    return serialize_zone(item)


@router.put("/zones/{zone_id}")
def update_zone(zone_id: str, payload: dict[str, Any], db: DbSession, _user: AdminOnly) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = db.get(CoreZone, zone_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Zona no encontrada")
    for key, value in payload.items():
        if hasattr(item, key):
            setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return serialize_zone(item)


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
    ensure_frontend_seed_data(db)
    query = select(CoreTask).order_by(CoreTask.fecha_programada)
    if estado is not None:
        query = query.where(CoreTask.estado == estado)
    if zona_id is not None:
        query = query.where(CoreTask.zona_id == zona_id)
    return [serialize_task(item) for item in db.scalars(query.offset(skip).limit(limit)).all()]


@router.post("/tasks", status_code=201)
def create_task(payload: dict[str, Any], db: DbSession, _user: TaskManager) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = CoreTask(
        id=payload.get("id", str(uuid4())),
        tarea_catalogo_id=payload.get("tarea_catalogo_id", str(uuid4())),
        tarea_catalogo=payload.get("tarea_catalogo"),
        zona_id=payload.get("zona_id"),
        fecha_programada=parse_datetime(payload.get("fecha_programada")) or utc_now().replace(tzinfo=None),
        fecha_ejecucion=parse_datetime(payload.get("fecha_ejecucion")),
        estado=payload.get("estado", "programada"),
        ejecutado_por=payload.get("ejecutado_por"),
        tiempo_ejecucion_minutos=payload.get("tiempo_ejecucion_minutos"),
        resultado=payload.get("resultado"),
        observaciones=payload.get("observaciones"),
        problemas_encontrados=payload.get("problemas_encontrados"),
        acciones_correctivas=payload.get("acciones_correctivas"),
        checklist_completado=payload.get("checklist_completado", "false"),
        checklist_datos=payload.get("checklist_datos"),
        es_urgente=bool(payload.get("es_urgente", False)),
        motivo_retraso=payload.get("motivo_retraso"),
        requiere_seguimiento=bool(payload.get("requiere_seguimiento", False)),
        fecha_seguimiento=parse_datetime(payload.get("fecha_seguimiento")),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return serialize_task(item)


@router.get("/tasks/{task_id}")
def task_detail(task_id: str, db: DbSession) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = db.get(CoreTask, task_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Tarea no encontrada")
    return serialize_task(item)


@router.put("/tasks/{task_id}")
def update_task(task_id: str, payload: dict[str, Any], db: DbSession, _user: TaskManager) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = db.get(CoreTask, task_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Tarea no encontrada")

    date_fields = {"fecha_programada", "fecha_ejecucion", "fecha_seguimiento"}
    for key, value in payload.items():
        if not hasattr(item, key):
            continue
        setattr(item, key, parse_datetime(value) if key in date_fields else value)

    db.commit()
    db.refresh(item)
    return serialize_task(item)


@router.get("/lactations")
def lactations(
    db: DbSession,
    skip: int = 0,
    limit: int = 50,
    animal_id: str | None = None,
    activa: bool | None = None,
) -> list[dict[str, Any]]:
    ensure_frontend_seed_data(db)
    query = select(CoreLactation).order_by(CoreLactation.fecha_inicio.desc())
    if animal_id is not None:
        query = query.where(CoreLactation.animal_id == animal_id)
    if activa is not None:
        query = query.where(CoreLactation.activa.is_(activa))
    return [serialize_lactation(item) for item in db.scalars(query.offset(skip).limit(limit)).all()]


@router.post("/lactations", status_code=201)
def create_lactation(payload: dict[str, Any], db: DbSession, _user: QualityManager) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = CoreLactation(
        id=payload.get("id", str(uuid4())),
        animal_id=payload["animal_id"],
        numero_lactacion=payload.get("numero_lactacion"),
        fecha_inicio=payload.get("fecha_inicio"),
        fecha_fin=payload.get("fecha_fin"),
        dias_transcurridos=payload.get("dias_transcurridos"),
        produccion_promedio=payload.get("produccion_promedio"),
        produccion_total=payload.get("produccion_total"),
        grasa_promedio=payload.get("grasa_promedio"),
        proteina_promedio=payload.get("proteina_promedio"),
        rcs_promedio=payload.get("rcs_promedio"),
        activa=bool(payload.get("activa", True)),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return serialize_lactation(item)


@router.put("/lactations/{lactation_id}")
def update_lactation(
    lactation_id: str,
    payload: dict[str, Any],
    db: DbSession,
    _user: QualityManager,
) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = db.get(CoreLactation, lactation_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Lactacion no encontrada")
    for key, value in payload.items():
        if hasattr(item, key):
            setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return serialize_lactation(item)


@router.get("/lactations/quality/summary")
def quality_summary(db: DbSession) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    items = db.scalars(select(CoreLactation).where(CoreLactation.activa.is_(True))).all()
    if not items:
        raise HTTPException(status_code=404, detail="No hay registros de lactacion")

    def avg(values: list[float | None]) -> float | None:
        usable = [value for value in values if value is not None]
        return round(sum(usable) / len(usable), 2) if usable else None

    return {
        "lactaciones_activas": len(items),
        "produccion_promedio": avg([item.produccion_promedio for item in items]),
        "grasa_promedio": avg([item.grasa_promedio for item in items]),
        "proteina_promedio": avg([item.proteina_promedio for item in items]),
        "rcs_promedio": avg([item.rcs_promedio for item in items]),
        "animales_en_control": len({item.animal_id for item in items}),
    }


@router.get("/alerts/critical")
def critical_alerts(db: DbSession) -> AlertsResponse:
    items = db.scalars(select(CoreAlert).where(CoreAlert.severidad.in_(["alta", "critica"]))).all()
    return alerts_response(list(items), 0, 50)


@router.get("/alerts")
def list_alerts(db: DbSession, skip: int = 0, limit: int = 50, severidad: str | None = None) -> AlertsResponse:
    query = select(CoreAlert).order_by(CoreAlert.fecha_creacion.desc())
    if severidad is not None:
        query = query.where(CoreAlert.severidad == severidad)
    items = list(db.scalars(query).all())
    return alerts_response(items, skip, limit)


@router.post("/alerts", status_code=201)
def create_alert(payload: AlertCreate, db: DbSession, _user: ClinicalManager) -> dict[str, Any]:
    confidence = payload.confianza_prediccion
    if confidence is not None and confidence > 1:
        confidence = confidence / 100
    item = CoreAlert(
        id=str(uuid4()),
        estado="pendiente",
        fecha_creacion=utc_now().replace(tzinfo=None),
        confianza_prediccion=confidence,
        revisada=False,
        requiere_escalacion=False,
        **payload.model_dump(exclude={"confianza_prediccion"}),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return serialize_alert(item)


@router.get("/alerts/detail/{alert_id}")
def alert_detail(alert_id: str, db: DbSession) -> dict[str, Any]:
    item = db.get(CoreAlert, alert_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Alerta no encontrada")
    return serialize_alert(item)


@router.patch("/alerts/{alert_id}")
def review_alert(alert_id: str, payload: AlertUpdate, db: DbSession, _user: ClinicalManager) -> dict[str, Any]:
    item = db.get(CoreAlert, alert_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Alerta no encontrada")
    updates = payload.model_dump(exclude_none=True)
    for key, value in updates.items():
        setattr(item, key, value)
    if payload.estado and payload.estado != "pendiente":
        item.fecha_revision = utc_now().replace(tzinfo=None)
        item.revisada = True
    db.commit()
    db.refresh(item)
    return serialize_alert(item)


@router.get("/alerts/{animal_id}")
def animal_alerts(animal_id: str, db: DbSession, skip: int = 0, limit: int = 50) -> AlertsResponse:
    items = list(db.scalars(select(CoreAlert).where(CoreAlert.animal_id == animal_id).order_by(CoreAlert.fecha_creacion.desc())).all())
    return alerts_response(items, skip, limit, animal_id=animal_id)


@router.post("/alerts/generate/{animal_id}")
def generate_alerts(animal_id: str, db: DbSession, _user: ClinicalManager) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    animal = db.get(CoreAnimal, animal_id)
    if animal is None:
        raise HTTPException(status_code=404, detail="Animal no encontrado")

    lactation = db.scalar(select(CoreLactation).where(CoreLactation.animal_id == animal_id, CoreLactation.activa.is_(True)))
    generated: list[CoreAlert] = []
    if lactation and lactation.rcs_promedio and lactation.rcs_promedio > 250000:
        existing = db.scalar(
            select(CoreAlert).where(
                CoreAlert.animal_id == animal_id,
                CoreAlert.tipo_alerta == "calidad_leche",
                CoreAlert.estado == "pendiente",
            )
        )
        if existing is None:
            generated.append(
                CoreAlert(
                    id=str(uuid4()),
                    animal_id=animal_id,
                    tipo_alerta="calidad_leche",
                    severidad="alta",
                    descripcion="Recuento de celulas somaticas por encima del umbral operativo.",
                    recomendacion="Revisar salud mamaria y muestra individual antes del siguiente ordeno.",
                    estado="pendiente",
                    confianza_prediccion=0.78,
                    requiere_escalacion=True,
                    fecha_creacion=utc_now().replace(tzinfo=None),
                    revisada=False,
                )
            )

    for item in generated:
        db.add(item)
    if generated:
        db.commit()

    return {"generated": len(generated), "alertas": [serialize_alert(item) for item in generated], "animal_id": animal_id}


@router.get("/predictions/{animal_id}")
def predictions(animal_id: str, db: DbSession) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    animal = db.get(CoreAnimal, animal_id)
    if animal is None:
        raise HTTPException(status_code=404, detail="Animal no encontrado")

    lactation = db.scalar(select(CoreLactation).where(CoreLactation.animal_id == animal_id, CoreLactation.activa.is_(True)))
    active_treatments = db.scalars(
        select(CoreTreatment).where(CoreTreatment.animal_id == animal_id, CoreTreatment.activo.is_(True))
    ).all()
    pending_alerts = db.scalars(
        select(CoreAlert).where(CoreAlert.animal_id == animal_id, CoreAlert.estado == "pendiente")
    ).all()

    base_production = lactation.produccion_promedio if lactation and lactation.produccion_promedio else 0
    treatment_penalty = 0.08 if active_treatments else 0
    alert_penalty = min(len(pending_alerts) * 0.03, 0.12)
    expected = round(base_production * (1 - treatment_penalty - alert_penalty), 1) if base_production else 0
    trend = "descenso" if treatment_penalty or alert_penalty else "estable"
    series = [round(expected * factor, 1) for factor in [0.98, 0.99, 1.0, 1.01, 1.0, 1.02, 1.01]]

    rcs = lactation.rcs_promedio if lactation else None
    risk_level = "alto" if (rcs and rcs > 250000) or active_treatments else "medio" if pending_alerts else "bajo"
    risk_factors = []
    if rcs and rcs > 250000:
        risk_factors.append("RCS por encima de umbral operativo")
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
            "grasa": {"prediccion": lactation.grasa_promedio if lactation and lactation.grasa_promedio else 0, "tendencia": "estable"},
            "proteina": {"prediccion": lactation.proteina_promedio if lactation and lactation.proteina_promedio else 0, "tendencia": "estable"},
            "lactosa": {"prediccion": 4.68, "tendencia": "estable"},
            "anomalia_detectada": bool(rcs and rcs > 250000),
            "confidence": 0.79 if lactation else 0.42,
        },
        "riesgo_sanitario": {
            "riesgo_promedio": risk_level,
            "riesgos_especificos": {
                "mastitis": {
                    "probabilidad": 0.68 if rcs and rcs > 250000 else 0.18,
                    "nivel": "alto" if rcs and rcs > 250000 else "bajo",
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
def incidents(db: DbSession, skip: int = 0, limit: int = 50) -> list[dict[str, Any]]:
    query = select(CoreIncident).order_by(CoreIncident.fecha_creacion.desc())
    return [serialize_incident(item) for item in db.scalars(query.offset(skip).limit(limit)).all()]


@router.post("/incidents", status_code=201)
def create_incident(payload: dict[str, Any], db: DbSession, _user: OperationsManager) -> dict[str, Any]:
    item = CoreIncident(
        id=str(uuid4()),
        tipo=payload.get("tipo", "Otra"),
        zona_id=payload.get("zona_id"),
        animal_id=payload.get("animal_id"),
        descripcion=payload.get("descripcion", ""),
        prioridad=payload.get("prioridad", "media"),
        estado="abierta",
        fecha_creacion=utc_now().replace(tzinfo=None),
        reportado_por=payload.get("reportado_por"),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return serialize_incident(item)


@router.get("/incidents/{incident_id}")
def incident_detail(incident_id: str, db: DbSession) -> dict[str, Any]:
    item = db.get(CoreIncident, incident_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Incidencia no encontrada")
    return serialize_incident(item)


@router.put("/incidents/{incident_id}")
def update_incident(incident_id: str, payload: dict[str, Any], db: DbSession, _user: OperationsManager) -> dict[str, Any]:
    item = db.get(CoreIncident, incident_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Incidencia no encontrada")
    for key, value in payload.items():
        if not hasattr(item, key):
            continue
        setattr(item, key, parse_datetime(value) if key == "fecha_resolucion" else value)
    db.commit()
    db.refresh(item)
    return serialize_incident(item)


@router.get("/treatments")
def treatments(
    db: DbSession,
    skip: int = 0,
    limit: int = 50,
    animal_id: str | None = None,
    activo: bool | None = None,
) -> list[dict[str, Any]]:
    ensure_frontend_seed_data(db)
    query = select(CoreTreatment).order_by(CoreTreatment.fecha_inicio.desc())
    if animal_id is not None:
        query = query.where(CoreTreatment.animal_id == animal_id)
    if activo is not None:
        query = query.where(CoreTreatment.activo.is_(activo))
    return [serialize_treatment(item) for item in db.scalars(query.offset(skip).limit(limit)).all()]


@router.post("/treatments", status_code=201)
def create_treatment(payload: dict[str, Any], db: DbSession, _user: ClinicalManager) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = CoreTreatment(
        id=payload.get("id", str(uuid4())),
        animal_id=payload["animal_id"],
        medicamento=payload.get("medicamento"),
        dosis=payload.get("dosis"),
        via_administracion=payload.get("via_administracion"),
        fecha_inicio=payload.get("fecha_inicio", utc_now().date().isoformat()),
        fecha_fin=payload.get("fecha_fin"),
        periodo_retirada_dias=payload.get("periodo_retirada_dias"),
        fecha_fin_retirada=payload.get("fecha_fin_retirada"),
        activo=bool(payload.get("activo", True)),
        motivo=payload.get("motivo"),
        veterinario=payload.get("veterinario"),
        observaciones=payload.get("observaciones"),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return serialize_treatment(item)


@router.get("/treatments/{treatment_id}")
def treatment_detail(treatment_id: str, db: DbSession) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = db.get(CoreTreatment, treatment_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Tratamiento no encontrado")
    return serialize_treatment(item)


@router.put("/treatments/{treatment_id}")
def update_treatment(treatment_id: str, payload: dict[str, Any], db: DbSession, _user: ClinicalManager) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = db.get(CoreTreatment, treatment_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Tratamiento no encontrado")
    for key, value in payload.items():
        if hasattr(item, key):
            setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return serialize_treatment(item)


@router.get("/employees")
def employees(db: DbSession, activo: bool | None = None) -> list[dict[str, Any]]:
    ensure_frontend_seed_data(db)
    query = select(CoreEmployee).order_by(CoreEmployee.nombre)
    if activo is not None:
        query = query.where(CoreEmployee.activo.is_(activo))
    return [serialize_employee(item) for item in db.scalars(query).all()]


@router.post("/employees", status_code=201)
def create_employee(payload: dict[str, Any], db: DbSession, _user: AdminOnly) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = CoreEmployee(
        id=payload.get("id", str(uuid4())),
        nombre=payload["nombre"],
        apellidos=payload.get("apellidos"),
        role=payload.get("role"),
        zona_principal_id=payload.get("zona_principal_id"),
        activo=bool(payload.get("activo", True)),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return serialize_employee(item)


@router.put("/employees/{employee_id}")
def update_employee(employee_id: str, payload: dict[str, Any], db: DbSession, _user: AdminOnly) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = db.get(CoreEmployee, employee_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Empleado no encontrado")
    for key, value in payload.items():
        if hasattr(item, key):
            setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return serialize_employee(item)


@router.get("/machinery")
def machinery(
    db: DbSession,
    skip: int = 0,
    limit: int = 50,
    estado: str | None = None,
    zona_id: str | None = None,
) -> list[dict[str, Any]]:
    ensure_frontend_seed_data(db)
    query = select(CoreMachinery).order_by(CoreMachinery.nombre)
    if estado is not None:
        query = query.where(CoreMachinery.estado == estado)
    if zona_id is not None:
        query = query.where(CoreMachinery.zona_id == zona_id)
    return [serialize_machinery(item) for item in db.scalars(query.offset(skip).limit(limit)).all()]


@router.post("/machinery", status_code=201)
def create_machinery(payload: dict[str, Any], db: DbSession, _user: OperationsManager) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = CoreMachinery(
        id=payload.get("id", str(uuid4())),
        nombre=payload["nombre"],
        tipo=payload.get("tipo", "general"),
        zona_id=payload.get("zona_id"),
        estado=payload.get("estado", "operativa"),
        proxima_revision=payload.get("proxima_revision"),
        observaciones=payload.get("observaciones"),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return serialize_machinery(item)


@router.put("/machinery/{machinery_id}")
def update_machinery(
    machinery_id: str,
    payload: dict[str, Any],
    db: DbSession,
    _user: OperationsManager,
) -> dict[str, Any]:
    ensure_frontend_seed_data(db)
    item = db.get(CoreMachinery, machinery_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Maquinaria no encontrada")
    for key, value in payload.items():
        if hasattr(item, key):
            setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return serialize_machinery(item)
