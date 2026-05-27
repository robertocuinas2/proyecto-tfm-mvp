from typing import Annotated, Any

from fastapi import APIRouter, Depends, Query
from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.tools4milk import LecturaMeteo
from app.services.aemet_client import aemet_client

router = APIRouter(prefix="/api/v1/weather", tags=["Weather"])

_NO_DATA = {"data": None, "message": "No hay datos meteorológicos cargados"}


@router.get("/current")
def weather_current(db: Annotated[Session, Depends(get_db)]) -> dict[str, Any]:
    row = db.execute(
        select(LecturaMeteo).order_by(desc(LecturaMeteo.ts)).limit(1)
    ).scalar_one_or_none()
    if row is None:
        return _NO_DATA
    return {
        "temperatura": float(row.temperatura_c) if row.temperatura_c is not None else None,
        "temperatura_actual": float(row.temperatura_c) if row.temperatura_c is not None else None,
        "humedad": float(row.humedad_relativa) if row.humedad_relativa is not None else None,
        "descripcion": None,
        "impacto_productivo": "normal",
        "fecha": row.ts.isoformat() if row.ts else None,
        "ubicacion": "Villalba, Lugo",
    }


@router.get("/forecast")
def weather_forecast(db: Annotated[Session, Depends(get_db)]) -> dict[str, Any]:
    rows = db.execute(
        select(LecturaMeteo).order_by(LecturaMeteo.ts).limit(7)
    ).scalars().all()
    return {
        "ubicacion": "Villalba, Lugo",
        "dias": [
            {
                "fecha": row.ts.isoformat() if row.ts else None,
                "temperatura_media": float(row.temperatura_c) if row.temperatura_c is not None else None,
                "temperatura_maxima": None,
                "temperatura_minima": None,
                "humedad": float(row.humedad_relativa) if row.humedad_relativa is not None else None,
                "precipitacion": float(row.precipitacion_mm) if row.precipitacion_mm is not None else None,
                "viento": float(row.viento_km_h) if row.viento_km_h is not None else None,
                "descripcion": None,
                "fuente": "AEMET",
            }
            for row in rows
        ],
    }


@router.get("/historical")
def weather_historical(
    db: Annotated[Session, Depends(get_db)],
    dias_atras: Annotated[int, Query(ge=1, le=365)] = 30,
) -> dict[str, Any]:
    rows = db.execute(
        select(LecturaMeteo).order_by(desc(LecturaMeteo.ts)).limit(dias_atras)
    ).scalars().all()
    return {
        "ubicacion": "Villalba, Lugo",
        "dias_atras": dias_atras,
        "datos": [
            {
                "fecha": row.ts.isoformat() if row.ts else None,
                "temperatura_media": float(row.temperatura_c) if row.temperatura_c is not None else None,
                "humedad": float(row.humedad_relativa) if row.humedad_relativa is not None else None,
                "descripcion": None,
                "fuente": "AEMET",
            }
            for row in rows
        ],
    }


@router.post("/sync")
async def weather_sync(db: Annotated[Session, Depends(get_db)]) -> dict[str, Any]:
    return await aemet_client.sincronizar_datos(db)


@router.get("/correlation/impact")
def weather_impact(dias_adelante: Annotated[int, Query(ge=1, le=30)] = 7) -> dict[str, Any]:
    return {
        "ubicacion": "Villalba, Lugo",
        "dias_adelante": dias_adelante,
        "impactos_predichos": [],
    }
