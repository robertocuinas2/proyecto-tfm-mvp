from sqlalchemy import select

from app.models import CoreAnimal, CoreAlert, CoreIncident, CoreTask


def test_simulation_requires_admin(client, operario_headers):
    response = client.post("/api/v1/simulation/tick", headers=operario_headers)
    assert response.status_code == 403


def test_simulation_status_reports_integrity(client, auth_headers):
    response = client.get("/api/v1/simulation/status", headers=auth_headers)
    assert response.status_code == 200
    payload = response.json()
    assert payload["enabled"] is True
    assert payload["counts"]["animals"] >= 1
    assert payload["integrity"]["ok"] is True
    assert payload["integrity"]["errors"] == []


def test_simulation_tick_moves_operational_data_without_breaking_refs(client, db, auth_headers):
    seeded = client.get("/api/v1/simulation/status", headers=auth_headers)
    assert seeded.status_code == 200
    before_animals = len(db.scalars(select(CoreAnimal)).all())

    response = client.post("/api/v1/simulation/tick?intensity=2", headers=auth_headers)
    assert response.status_code == 200
    payload = response.json()

    assert payload["ok"] is True
    assert payload["integrity"]["ok"] is True
    assert payload["integrity"]["errors"] == []
    assert sum(payload["operations"].values()) > 0

    after_animals = len(db.scalars(select(CoreAnimal)).all())
    assert after_animals == before_animals
    assert len(db.scalars(select(CoreTask)).all()) >= 1
    assert len(db.scalars(select(CoreAlert)).all()) >= 1
    assert len(db.scalars(select(CoreIncident)).all()) >= 1
