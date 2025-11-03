from fastapi import APIRouter
from app.schemas.deck import DeckResponse

router = APIRouter()

@router.get("/", response_model=list[DeckResponse])
def get_decks():
    return [{"message": "Decks endpoint"}]
