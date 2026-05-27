from typing import Annotated, Any

from fastapi import APIRouter, Depends, Query
from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import DatosMetereologicos
from app.services.aemet_client import aemet_client


router = APIRouter(prefix="/api/v1/weather", tags=["Weather"])


@router.get("/current")
def weather_current(db: Annotated[Session, Depends(get_db)]) -> dict[str, Any]:
    dato = db.execute(
        select(DatosMetereologicos).order_by(desc(DatosMetereologicos.fecha_hora)).limit(1)
    ).scalar_one_or_none()
    if dato is None:
        return {
            "temperatura": 17.5,
            "temperatura_actual": 17.5,
            "humedad": 65,
            "descripcion": "Sin datos recientes",
            "impacto_productivo": "normal",
            "fecha": None,
        }
    return {
        "temperatura": dato.temperatura_media,
        "temperatura_actual": dato.temperatura_media,
        "humedad": dato.humedad_relativa,
        "descripcion": dato.estado_cielo,
        "impacto_productivo": "normal",
        "fecha": dato.fecha_hora.isoformat() if dato.fecha_hora else None,
        "ubicacion": dato.ubicacion,
    }


@router.get("/forecast")
def weather_forecast(db: Annotated[Session, Depends(get_db)]) -> dict[str, Any]:
    rows = db.execute(
        select(DatosMetereologicos).order_by(DatosMetereologicos.fecha_hora).limit(7)
    ).scalars().all()
    return {
        "ubicacion": "Villalba, Lugo",
        "dias": [
            {
                "fecha": row.fecha_hora.isoformat() if row.fecha_hora else None,
                "temperatura_media": row.temperatura_media,
                "temperatura_maxima": row.temperatura_maxima,
                "temperatura_minima": row.temperatura_minima,
                "humedad": row.humedad_relativa,
                "precipitacion": row.precipitacion,
                "viento": row.velocidad_viento,
                "descripcion": row.estado_cielo,
                "fuente": row.fuente,
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
        select(DatosMetereologicos).order_by(desc(DatosMetereologicos.fecha_hora)).limit(dias_atras)
    ).scalars().all()
    return {
        "ubicacion": "Villalba, Lugo",
        "dias_atras": dias_atras,
        "datos": [
            {
                "fecha": row.fecha_hora.isoformat() if row.fecha_hora else None,
                "temperatura_media": row.temperatura_media,
                "humedad": row.humedad_relativa,
                "descripcion": row.estado_cielo,
                "fuente": row.fuente,
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
