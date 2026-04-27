from fastapi import APIRouter,Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app import models
from app.schemas.deck import DeckCreate, DeckResponse
from pydantic import BaseModel
from typing import List
import datetime
import uuid
router = APIRouter(prefix="/decks", tags=["decks"])



@router.get("/", response_model=list[DeckResponse])
def get_decks(db: Session = Depends(get_db)):
    return db.query(models.Deck).all()

@router.post("/", response_model=DeckResponse)
def create_deck(deck: DeckCreate, db: Session = Depends(get_db)):
    db_deck = models.Deck(
        title=deck.title,
        description=deck.description,
        user_id=1
    )
    db.add(db_deck)
    db.commit()
    db.refresh(db_deck)
    return db_deck

@router.get("/{deck_id}", response_model=DeckResponse)
def get_deck(deck_id: int, db: Session = Depends(get_db)):
    deck = db.query(models.Deck).filter(models.Deck.id == deck_id).first()
    if not deck:
        raise HTTPException(status_code=404, detail="Колода не найдена")
    return deck

@router.put("/{deck_id}", response_model=DeckResponse)
def update_deck(deck_id: int, deck_update: DeckCreate, db: Session = Depends(get_db)):
    deck = db.query(models.Deck).filter(models.Deck.id == deck_id).first()
    if not deck:
        raise HTTPException(status_code=404, detail="Колода не найдена")
    deck.title = deck_update.title
    deck.description = deck_update.description
    db.commit()
    db.refresh(deck)
    return deck

@router.delete("/{deck_id}")
def delete_deck(deck_id: int, db: Session = Depends(get_db)):
    deck = db.query(models.Deck).filter(models.Deck.id == deck_id).first()
    if not deck:
        raise HTTPException(status_code=404, detail="Колода не найдена")
    db.delete(deck)
    db.commit()
    return {"message": "Колода удалена"}