from datetime import datetime, timedelta
from typing import Any

import httpx
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import settings
from app.models.datos_metereologicos import DatosMetereologicos
from app.time_utils import utc_now


class AemetClient:
    api_base_url = "https://opendata.aemet.es/opendata/api"
    location_name = "Villalba, Lugo"
    latitud = 42.6447
    longitud = -8.1278

    async def sincronizar_datos(self, db: Session) -> dict[str, object]:
        if settings.aemet_api_key.strip():
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
            return self._upsert_records(db, records, mode="aemet_real")

        records = self._generated_records()
        summary = self._upsert_records(db, records, mode="simulado_sin_api_key")
        summary["status"] = "success"
        return summary

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
        temperatura_media = self._average(maxima, minima)
        humedad = self._average(
            self._to_float(day.get("humedadRelativa", {}).get("maxima")),
            self._to_float(day.get("humedadRelativa", {}).get("minima")),
        )
        precipitacion = self._max_period_value(day.get("probPrecipitacion", []))
        viento = self._first_wind_speed(day.get("viento", []))
        estado_cielo = self._first_description(day.get("estadoCielo", []))

        return {
            "fecha_hora": fecha.replace(hour=12, minute=0, second=0, microsecond=0),
            "temperatura_media": temperatura_media,
            "temperatura_maxima": maxima,
            "temperatura_minima": minima,
            "humedad_relativa": humedad,
            "precipitacion": precipitacion,
            "velocidad_viento": viento,
            "presion_atmosferica": None,
            "estado_cielo": estado_cielo or "sin descripcion",
            "ubicacion": self.location_name,
            "latitud": self.latitud,
            "longitud": self.longitud,
            "fuente": "AEMET",
        }

    def _generated_records(self) -> list[dict[str, Any]]:
        records: list[dict[str, Any]] = []
        base = utc_now().replace(hour=12, minute=0, second=0, microsecond=0)
        for offset in range(7):
            records.append(
                {
                    "fecha_hora": (base + timedelta(days=offset)).replace(tzinfo=None),
                    "temperatura_media": 16.5 + offset * 0.3,
                    "temperatura_maxima": 21 + offset * 0.4,
                    "temperatura_minima": 10 + offset * 0.2,
                    "humedad_relativa": 65,
                    "precipitacion": 0 if offset % 3 else 1.5,
                    "velocidad_viento": 4.5,
                    "presion_atmosferica": 1013,
                    "estado_cielo": "parcialmente nublado",
                    "ubicacion": self.location_name,
                    "latitud": self.latitud,
                    "longitud": self.longitud,
                    "fuente": "AEMET",
                }
            )
        return records

    def _upsert_records(self, db: Session, records: list[dict[str, Any]], mode: str) -> dict[str, object]:
        inserted = 0
        updated = 0

        for record in records:
            existing = db.execute(
                select(DatosMetereologicos).where(DatosMetereologicos.fecha_hora == record["fecha_hora"])
            ).scalar_one_or_none()
            if existing:
                for key, value in record.items():
                    setattr(existing, key, value)
                updated += 1
                continue
            db.add(DatosMetereologicos(**record))
            inserted += 1

        db.commit()
        return {
            "status": "success",
            "modo": mode,
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

    @staticmethod
    def _first_description(entries: list[dict[str, Any]]) -> str | None:
        for item in entries:
            description = item.get("descripcion") or item.get("value")
            if description:
                return str(description)
        return None


aemet_client = AemetClient()
