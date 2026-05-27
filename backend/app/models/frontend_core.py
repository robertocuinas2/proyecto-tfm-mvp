from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class CoreAnimal(Base):
    __tablename__ = "core_animals"

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    crotal_oficial: Mapped[str] = mapped_column(String(80), unique=True, index=True)
    nombre: Mapped[str] = mapped_column(String(120), nullable=True)
    sexo: Mapped[str] = mapped_column(String(40))
    fecha_nacimiento: Mapped[str] = mapped_column(String(20))
    raza: Mapped[str] = mapped_column(String(80), nullable=True)
    estado: Mapped[str] = mapped_column(String(40), index=True)
    estado_reproductivo: Mapped[str] = mapped_column(String(80), nullable=True)
    fecha_entrada: Mapped[str] = mapped_column(String(20))
    fecha_baja: Mapped[str] = mapped_column(String(20), nullable=True)
    motivo_baja: Mapped[str] = mapped_column(String(255), nullable=True)
    notas: Mapped[str] = mapped_column(Text, nullable=True)


class CoreZone(Base):
    __tablename__ = "core_zones"

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    nombre: Mapped[str] = mapped_column(String(120))
    codigo: Mapped[str] = mapped_column(String(20), unique=True)
    descripcion: Mapped[str] = mapped_column(Text, nullable=True)
    tipo: Mapped[str] = mapped_column(String(80), nullable=True)
    tiene_pantalla_tv: Mapped[bool] = mapped_column(Boolean, default=True)
    tiene_tablet: Mapped[bool] = mapped_column(Boolean, default=True)
    activa: Mapped[bool] = mapped_column(Boolean, default=True)


class CoreTask(Base):
    __tablename__ = "core_tasks"

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    tarea_catalogo_id: Mapped[str] = mapped_column(String(80))
    tarea_catalogo: Mapped[dict] = mapped_column(JSON, nullable=True)
    zona_id: Mapped[str] = mapped_column(String(80), index=True, nullable=True)
    fecha_programada: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    fecha_ejecucion: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=True)
    estado: Mapped[str] = mapped_column(String(40), index=True)
    ejecutado_por: Mapped[str] = mapped_column(String(120), nullable=True)
    tiempo_ejecucion_minutos: Mapped[str] = mapped_column(String(40), nullable=True)
    resultado: Mapped[str] = mapped_column(String(120), nullable=True)
    observaciones: Mapped[str] = mapped_column(Text, nullable=True)
    problemas_encontrados: Mapped[str] = mapped_column(Text, nullable=True)
    acciones_correctivas: Mapped[str] = mapped_column(Text, nullable=True)
    checklist_completado: Mapped[str] = mapped_column(String(10), default="false")
    checklist_datos: Mapped[str] = mapped_column(Text, nullable=True)
    es_urgente: Mapped[bool] = mapped_column(Boolean, default=False)
    motivo_retraso: Mapped[str] = mapped_column(Text, nullable=True)
    requiere_seguimiento: Mapped[bool] = mapped_column(Boolean, default=False)
    fecha_seguimiento: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=True)


class CoreAlert(Base):
    __tablename__ = "core_alerts"

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    animal_id: Mapped[str] = mapped_column(String(80), index=True)
    tipo_alerta: Mapped[str] = mapped_column(String(120))
    severidad: Mapped[str] = mapped_column(String(40), index=True)
    descripcion: Mapped[str] = mapped_column(Text)
    recomendacion: Mapped[str] = mapped_column(Text, nullable=True)
    estado: Mapped[str] = mapped_column(String(40), index=True, default="pendiente")
    confianza_prediccion: Mapped[float] = mapped_column(Float, nullable=True)
    requiere_escalacion: Mapped[bool] = mapped_column(Boolean, default=False)
    fecha_creacion: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    fecha_revision: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=True)
    revisada: Mapped[bool] = mapped_column(Boolean, default=False)
    notas_operario: Mapped[str] = mapped_column(Text, nullable=True)
    accion_tomada: Mapped[str] = mapped_column(Text, nullable=True)
    veterinario_responsable: Mapped[str] = mapped_column(String(120), nullable=True)


class CoreIncident(Base):
    __tablename__ = "core_incidents"

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    tipo: Mapped[str] = mapped_column(String(120))
    zona_id: Mapped[str] = mapped_column(String(80), index=True, nullable=True)
    animal_id: Mapped[str] = mapped_column(String(80), index=True, nullable=True)
    descripcion: Mapped[str] = mapped_column(Text)
    prioridad: Mapped[str] = mapped_column(String(40), index=True)
    estado: Mapped[str] = mapped_column(String(40), index=True, default="abierta")
    fecha_creacion: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    fecha_resolucion: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=True)
    resolucion: Mapped[str] = mapped_column(Text, nullable=True)
    reportado_por: Mapped[str] = mapped_column(String(120), nullable=True)


class CoreLactation(Base):
    __tablename__ = "core_lactations"

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    animal_id: Mapped[str] = mapped_column(String(80), index=True)
    numero_lactacion: Mapped[int] = mapped_column(nullable=True)
    fecha_inicio: Mapped[str] = mapped_column(String(20), nullable=True)
    fecha_fin: Mapped[str] = mapped_column(String(20), nullable=True)
    dias_transcurridos: Mapped[int] = mapped_column(nullable=True)
    produccion_promedio: Mapped[float] = mapped_column(Float, nullable=True)
    produccion_total: Mapped[float] = mapped_column(Float, nullable=True)
    grasa_promedio: Mapped[float] = mapped_column(Float, nullable=True)
    proteina_promedio: Mapped[float] = mapped_column(Float, nullable=True)
    rcs_promedio: Mapped[float] = mapped_column(Float, nullable=True)
    activa: Mapped[bool] = mapped_column(Boolean, default=True)


class CoreTreatment(Base):
    __tablename__ = "core_treatments"

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    animal_id: Mapped[str] = mapped_column(String(80), index=True)
    medicamento: Mapped[str] = mapped_column(String(160), nullable=True)
    dosis: Mapped[str] = mapped_column(String(120), nullable=True)
    via_administracion: Mapped[str] = mapped_column(String(80), nullable=True)
    fecha_inicio: Mapped[str] = mapped_column(String(20))
    fecha_fin: Mapped[str] = mapped_column(String(20), nullable=True)
    periodo_retirada_dias: Mapped[int] = mapped_column(nullable=True)
    fecha_fin_retirada: Mapped[str] = mapped_column(String(20), nullable=True)
    activo: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    motivo: Mapped[str] = mapped_column(Text, nullable=True)
    veterinario: Mapped[str] = mapped_column(String(120), nullable=True)
    observaciones: Mapped[str] = mapped_column(Text, nullable=True)


class CoreEmployee(Base):
    __tablename__ = "core_employees"

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    nombre: Mapped[str] = mapped_column(String(120))
    apellidos: Mapped[str] = mapped_column(String(160), nullable=True)
    role: Mapped[str] = mapped_column(String(80), nullable=True)
    zona_principal_id: Mapped[str] = mapped_column(String(80), nullable=True)
    activo: Mapped[bool] = mapped_column(Boolean, default=True, index=True)


class CoreMachinery(Base):
    __tablename__ = "core_machinery"

    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    nombre: Mapped[str] = mapped_column(String(160))
    tipo: Mapped[str] = mapped_column(String(80))
    zona_id: Mapped[str] = mapped_column(String(80), nullable=True)
    estado: Mapped[str] = mapped_column(String(80), default="operativa", index=True)
    proxima_revision: Mapped[str] = mapped_column(String(20), nullable=True)
    observaciones: Mapped[str] = mapped_column(Text, nullable=True)
