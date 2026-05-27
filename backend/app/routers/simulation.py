from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models import Usuario
from app.security import require_roles
from app.services.simulation_service import run_simulation_tick, simulation_status


router = APIRouter(prefix="/api/v1/simulation", tags=["Simulation"])
DbSession = Annotated[Session, Depends(get_db)]
AdminOnly = Annotated[Usuario, Depends(require_roles("admin"))]


@router.get("/status")
def status(db: DbSession, _user: AdminOnly) -> dict[str, Any]:
    return simulation_status(db)


@router.post("/tick")
def tick(
    db: DbSession,
    _user: AdminOnly,
    intensity: Annotated[int, Query(ge=1, le=5)] = 1,
) -> dict[str, Any]:
    if not settings.enable_simulation:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="El modo simulacion esta desactivado",
        )
    return run_simulation_tick(db, intensity=intensity)
