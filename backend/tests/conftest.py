"""
Configuración y fixtures para tests de Tools4Milk MVP
"""

import pytest
import os
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, select
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

os.environ["REDIS_ENABLED"] = "False"
os.environ["AEMET_API_KEY"] = ""

from app.time_utils import utc_now

from app.main import app
from app.database import Base, get_db
from app.config import settings
from app.models.usuario import Usuario
from app.security import hash_password
import uuid

# Crear base de datos de prueba en memoria
SQLALCHEMY_TEST_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)

TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)


def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture
def db():
    """Proporciona una sesión de base de datos de prueba"""
    Base.metadata.create_all(bind=engine)
    yield TestingSessionLocal()
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def client():
    """Proporciona un cliente TestClient para la API"""
    Base.metadata.create_all(bind=engine)
    with TestClient(app) as test_client:
        yield test_client
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def test_user(db):
    """
    Crea un usuario de prueba en la base de datos

    Returns:
        Usuario con credenciales:
        - username: "testuser"
        - email: "test@example.com"
        - password: "testpass123" (hashado)
    """
    user = Usuario(
        id=uuid.uuid4(),
        username="testuser",
        email="test@example.com",
        hashed_password=hash_password("testpass123"),
        role="admin",
        activo=True,
        debe_cambiar_contrasena=False,
        fecha_creacion=utc_now()
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@pytest.fixture
def test_user_credentials():
    """Proporciona credenciales de usuario para pruebas"""
    return {
        "username": "testuser",
        "password": "testpass123"
    }


@pytest.fixture
def test_inactive_user(db):
    """
    Crea un usuario inactivo en la base de datos

    Returns:
        Usuario inactivo con credenciales:
        - username: "inactiveuser"
        - email: "inactive@example.com"
        - password: "inactivepass123"
    """
    user = Usuario(
        id=uuid.uuid4(),
        username="inactiveuser",
        email="inactive@example.com",
        hashed_password=hash_password("inactivepass123"),
        role="operario",
        activo=False,
        debe_cambiar_contrasena=False,
        fecha_creacion=utc_now()
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@pytest.fixture
def auth_headers(client):
    ensure_test_user("admin", "admin@tools4milk.local", "admin")
    response = client.post(
        "/api/v1/auth/login",
        json={"username": "admin", "password": "testpass123"},
    )
    assert response.status_code == 200
    token = response.json()["token"]["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def operario_headers(client):
    ensure_test_user("laura.fernandez", "laura.fernandez@tools4milk.local", "alimentacion")
    response = client.post(
        "/api/v1/auth/login",
        json={"username": "laura.fernandez", "password": "testpass123"},
    )
    assert response.status_code == 200
    token = response.json()["token"]["access_token"]
    return {"Authorization": f"Bearer {token}"}


def ensure_test_user(username: str, email: str, role: str) -> None:
    db = TestingSessionLocal()
    try:
        user = db.execute(select(Usuario).where(Usuario.username == username)).scalar_one_or_none()
        password_hash = hash_password("testpass123")
        if user is None:
            db.add(
                Usuario(
                    id=uuid.uuid4(),
                    username=username,
                    email=email,
                    hashed_password=password_hash,
                    role=role,
                    activo=True,
                    debe_cambiar_contrasena=False,
                    fecha_creacion=utc_now(),
                )
            )
        else:
            user.email = email
            user.hashed_password = password_hash
            user.role = role
            user.activo = True
        db.commit()
    finally:
        db.close()
