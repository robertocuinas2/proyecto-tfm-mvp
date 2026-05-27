from sqlalchemy import select

from app.config import settings
from app.models import CoreIncident


def test_assistant_is_disabled_by_default(client, auth_headers):
    response = client.post(
        "/api/v1/assistant/message",
        headers=auth_headers,
        json={"message": "dame el estado de la explotacion"},
    )

    assert response.status_code == 403


def test_assistant_rejects_animal_creation(client, auth_headers, monkeypatch):
    monkeypatch.setattr(settings, "enable_assistant", True)
    response = client.post(
        "/api/v1/assistant/message",
        headers=auth_headers,
        json={"message": "crea una vaca nueva llamada Luna"},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["action"] == "forbidden"
    assert "No puedo crear animales" in payload["reply"]


def test_assistant_status_is_available_to_authenticated_users(client, operario_headers, monkeypatch):
    monkeypatch.setattr(settings, "enable_assistant", True)
    response = client.post(
        "/api/v1/assistant/message",
        headers=operario_headers,
        json={"message": "dame el estado de la explotacion"},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["action"] == "query_status"
    assert payload["result"]["pending_alerts"] >= 0


def test_assistant_creates_incident_only_after_confirmation(client, db, auth_headers, monkeypatch):
    monkeypatch.setattr(settings, "enable_assistant", True)
    proposal = client.post(
        "/api/v1/assistant/message",
        headers=auth_headers,
        json={"message": "crea una incidencia en sala de ordeno porque el robot 1 no lava bien"},
    )

    assert proposal.status_code == 200
    payload = proposal.json()
    assert payload["action"] == "create_incident"
    assert payload["requires_confirmation"] is True
    assert payload["missing_fields"] == []
    assert len(db.scalars(select(CoreIncident)).all()) == 0

    confirmed = client.post(
        "/api/v1/assistant/message",
        headers=auth_headers,
        json={"message": "confirmo", "confirmed": True, "draft": payload["draft"]},
    )

    assert confirmed.status_code == 200
    result = confirmed.json()
    assert result["result"]["id"]
    assert len(db.scalars(select(CoreIncident)).all()) == 1


def test_assistant_blocks_clinical_actions_by_role(client, operario_headers, monkeypatch):
    monkeypatch.setattr(settings, "enable_assistant", True)
    proposal = client.post(
        "/api/v1/assistant/message",
        headers=operario_headers,
        json={"message": "crea tratamiento para animal-001 con ceftiofur dosis 10 ml"},
    )
    assert proposal.status_code == 200
    payload = proposal.json()
    assert payload["requires_confirmation"] is True

    confirmed = client.post(
        "/api/v1/assistant/message",
        headers=operario_headers,
        json={"message": "confirmo", "confirmed": True, "draft": payload["draft"]},
    )
    assert confirmed.status_code == 403
