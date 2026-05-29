"""
db.py — Utilidades de base de datos para el sistema de demo de Tools4Milk.

Gestiona la conexión, la validación de tablas/columnas y helpers de ejecución.
No importa modelos del backend; opera con SQLAlchemy Core y text().
"""

import sys
from typing import Any

from sqlalchemy import create_engine, text, inspect
from sqlalchemy.engine import Engine

from demo_config import DATABASE_URL, TABLAS_CRITICAS


def get_engine() -> Engine:
    """Crea y devuelve un engine SQLAlchemy con la DATABASE_URL configurada."""
    try:
        engine = create_engine(DATABASE_URL, pool_pre_ping=True)
        # Verificar conexión
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return engine
    except Exception as exc:
        print(f"\n[ERROR] No se pudo conectar a la base de datos.")
        print(f"  DATABASE_URL: {DATABASE_URL}")
        print(f"  Error: {exc}")
        print(
            "\n  Si usas Docker, asegúrate de que el contenedor 'db' esté levantado:"
            "\n    docker compose up -d db"
            "\n  y ajusta DATABASE_URL a:"
            "\n    postgresql+psycopg://postgres:postgres@db:5432/tools4milk"
        )
        sys.exit(1)


def validate_tables(engine: Engine) -> None:
    """
    Verifica que las tablas críticas existen en la base de datos.
    Aborta con mensaje claro si falta alguna.
    """
    insp = inspect(engine)
    existing = set(insp.get_table_names())
    missing = [t for t in TABLAS_CRITICAS if t not in existing]

    if missing:
        print(f"\n[ERROR] Faltan tablas críticas en la base de datos:")
        for t in missing:
            print(f"  - {t}")
        print(
            "\n  Asegúrate de que el contenedor de base de datos ha ejecutado init.sql."
            "\n  Para reinicializar: docker compose down -v && docker compose up -d db"
        )
        sys.exit(1)

    print(f"[OK] Tablas validadas: {len(TABLAS_CRITICAS)} tablas requeridas presentes.")


def validate_column(engine: Engine, table: str, column: str) -> bool:
    """Devuelve True si la columna existe en la tabla."""
    insp = inspect(engine)
    cols = {c["name"] for c in insp.get_columns(table)}
    return column in cols


def fetchall(conn, query: str, params: dict | None = None) -> list[dict]:
    """Ejecuta una query y devuelve lista de dicts."""
    result = conn.execute(text(query), params or {})
    keys = result.keys()
    return [dict(zip(keys, row)) for row in result.fetchall()]


def fetchone(conn, query: str, params: dict | None = None) -> dict | None:
    """Ejecuta una query y devuelve el primer resultado como dict o None."""
    result = conn.execute(text(query), params or {})
    row = result.fetchone()
    if row is None:
        return None
    return dict(zip(result.keys(), row))


def execute(conn, query: str, params: dict | None = None) -> Any:
    """Ejecuta una query DML y devuelve el result."""
    return conn.execute(text(query), params or {})


def count_demo_records(conn, table: str, condition: str) -> int:
    """Cuenta registros demo en una tabla usando la condición dada."""
    try:
        result = conn.execute(text(f"SELECT COUNT(*) FROM {table} WHERE {condition}"))
        return result.scalar() or 0
    except Exception:
        return 0
