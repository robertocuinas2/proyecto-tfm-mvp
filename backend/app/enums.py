"""
Enumeraciones para tipos específicos de PostgreSQL.
"""

from enum import Enum


class EstadoTarea(str, Enum):
    """Estados de tareas (tareas_ejecuciones.estado)."""
    PENDIENTE = "pendiente"
    EN_CURSO = "en_curso"
    COMPLETADA = "completada"
    VENCIDA = "vencida"
    CANCELADA = "cancelada"


class EstadoAnimal(str, Enum):
    """Estados de animales (animales.estado)."""
    PRODUCCION = "produccion"
    SECA = "seca"
    RECRIA = "recria"
    GESTANTE = "gestante"
    BAJA = "baja"


class EstadoPedido(str, Enum):
    """Estados de pedidos (pedidos.estado)."""
    SOLICITADO = "solicitado"
    APROBADO = "aprobado"
    EN_TRANSITO = "en_transito"
    RECIBIDO = "recibido"
    CANCELADO = "cancelado"


class EstadoIncidencia(str, Enum):
    """Estados de incidencias (incidencias.estado)."""
    ABIERTA = "abierta"
    EN_GESTION = "en_gestion"
    RESUELTA = "resuelta"
    CERRADA = "cerrada"


class NivelAlerta(str, Enum):
    """Niveles de alerta (alertas.nivel)."""
    BAJA = "baja"
    MEDIA = "media"
    ALTA = "alta"
