from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models import Usuario
from app.schemas.api import AssistantMessageRequest, AssistantResponse
from app.security import get_current_user
from app.services.assistant_service import handle_assistant_message


router = APIRouter(prefix="/api/v1/assistant", tags=["Assistant"])
DbSession = Annotated[Session, Depends(get_db)]
CurrentUser = Annotated[Usuario, Depends(get_current_user)]


@router.post("/message", response_model=AssistantResponse)
def message(payload: AssistantMessageRequest, db: DbSession, user: CurrentUser) -> AssistantResponse:
    if not settings.enable_assistant:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="El asistente operativo esta desactivado",
        )
    return AssistantResponse(
        **handle_assistant_message(
            db=db,
            user=user,
            message=payload.message,
            confirmed=payload.confirmed,
            draft=payload.draft,
        )
    )
