from datetime import datetime
from typing import Any

import httpx
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import settings
from app.models.tools4milk import LecturaMeteo
from app.time_utils import utc_now

ESTACION_ID = "villalba_lugo"


class AemetClient:
    api_base_url = "https://opendata.aemet.es/opendata/api"
    location_name = "Villalba, Lugo"
    latitud = 42.6447
    longitud = -8.1278

    async def sincronizar_datos(self, db: Session) -> dict[str, object]:
        if not settings.aemet_api_key.strip():
            return {
                "status": "skipped",
                "modo": "sin_api_key",
                "mensaje": "No hay API key de AEMET configurada. Configura AEMET_API_KEY para activar la sincronización.",
                "registros_insertados": 0,
                "registros_actualizados": 0,
                "timestamp": utc_now().isoformat(),
            }

        try:
            records = await self._fetch_real_forecast()
        except (httpx.HTTPError, ValueError, KeyError, TypeError) as exc:
            return {
                "status": "error",
                "modo": "aemet_real",
                "error": str(exc) or exc.__class__.__name__,
                "registros_insertados": 0,
                "registros_actualizados": 0,
                "timestamp": utc_now().isoformat(),
            }

        return self._upsert_records(db, records)

    async def _fetch_real_forecast(self) -> list[dict[str, Any]]:
        endpoint = f"{self.api_base_url}/prediccion/especifica/municipio/diaria/{settings.aemet_municipio_id}"
        headers = {"cache-control": "no-cache"}
        params = {"api_key": settings.aemet_api_key}
        async with httpx.AsyncClient(timeout=20) as client:
            metadata_response = await client.get(endpoint, params=params, headers=headers)
            metadata_response.raise_for_status()
            metadata = metadata_response.json()
            data_url = metadata.get("datos")
            if not data_url:
                raise ValueError(metadata.get("descripcion") or "AEMET no devolvio URL de datos")

            data_response = await client.get(data_url, headers=headers)
            data_response.raise_for_status()
            payload = data_response.json()

        municipality = payload[0] if isinstance(payload, list) and payload else payload
        days = municipality.get("prediccion", {}).get("dia", [])
        records = [self._parse_forecast_day(day) for day in days if day.get("fecha")]
        if not records:
            raise ValueError("AEMET no devolvio dias de prediccion para el municipio configurado")
        return records

    def _parse_forecast_day(self, day: dict[str, Any]) -> dict[str, Any]:
        fecha = datetime.fromisoformat(day["fecha"].replace("Z", "+00:00")).replace(tzinfo=None)
        maxima = self._to_float(day.get("temperatura", {}).get("maxima"))
        minima = self._to_float(day.get("temperatura", {}).get("minima"))
        temperatura_c = self._average(maxima, minima)
        humedad = self._average(
            self._to_float(day.get("humedadRelativa", {}).get("maxima")),
            self._to_float(day.get("humedadRelativa", {}).get("minima")),
        )
        precipitacion_mm = self._max_period_value(day.get("probPrecipitacion", []))
        viento_km_h = self._first_wind_speed(day.get("viento", []))

        return {
            "ts": fecha.replace(hour=12, minute=0, second=0, microsecond=0),
            "estacion_id": ESTACION_ID,
            "temperatura_c": temperatura_c,
            "humedad_relativa": humedad,
            "precipitacion_mm": precipitacion_mm,
            "viento_km_h": viento_km_h,
        }

    def _upsert_records(self, db: Session, records: list[dict[str, Any]]) -> dict[str, object]:
        inserted = 0
        updated = 0

        for record in records:
            existing = db.execute(
                select(LecturaMeteo).where(
                    LecturaMeteo.ts == record["ts"],
                    LecturaMeteo.estacion_id == record["estacion_id"],
                )
            ).scalar_one_or_none()
            if existing:
                for key, value in record.items():
                    setattr(existing, key, value)
                updated += 1
                continue
            db.add(LecturaMeteo(**record))
            inserted += 1

        db.commit()
        return {
            "status": "success",
            "modo": "aemet_real",
            "registros_insertados": inserted,
            "registros_actualizados": updated,
            "timestamp": utc_now().isoformat(),
        }

    @staticmethod
    def _to_float(value: Any) -> float | None:
        if value in (None, ""):
            return None
        try:
            return float(value)
        except (TypeError, ValueError):
            return None

    @staticmethod
    def _average(*values: float | None) -> float | None:
        usable = [value for value in values if value is not None]
        return round(sum(usable) / len(usable), 2) if usable else None

    def _max_period_value(self, entries: list[dict[str, Any]]) -> float | None:
        values = [self._to_float(item.get("value")) for item in entries]
        usable = [value for value in values if value is not None]
        return max(usable) if usable else None

    def _first_wind_speed(self, entries: list[dict[str, Any]]) -> float | None:
        for item in entries:
            value = self._to_float(item.get("velocidad"))
            if value is not None:
                return value
        return None


aemet_client = AemetClient()
