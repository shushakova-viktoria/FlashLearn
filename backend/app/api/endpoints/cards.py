from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from app.database import get_db
from app import models
from app.services.srs_service import SRSService, SRSReview
from app.schemas.card import CardResponse, CardCreate, ReviewResponse, ReviewCard, ReviewRequest, CardUpdate

router = APIRouter(prefix="/cards", tags=["cards"])


@router.post("/", response_model=CardResponse)
def create_card(card: CardCreate, db: Session = Depends(get_db)):
    """Создание новой карточки"""
    deck = db.query(models.Deck).filter(models.Deck.id == card.deck_id).first()
    if not deck:
        raise HTTPException(status_code=404, detail="Колода не найдена")

    db_card = models.Card(
        question=card.question,
        answer=card.answer,
        deck_id=card.deck_id,
        ease_factor=2.5,
        interval=0,
        repetitions=0,
        next_review=datetime.utcnow()
    )
    db.add(db_card)
    db.commit()
    db.refresh(db_card)
    return db_card


@router.put("/{card_id}", response_model=CardResponse)
def update_card(card_id: int, card_update: CardUpdate, db: Session = Depends(get_db)):
    """Обновление карточки"""
    card = db.query(models.Card).filter(models.Card.id == card_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Карточка не найдена")

    update_data = card_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(card, field, value)

    db.commit()
    db.refresh(card)
    return card


@router.get("/review", response_model=list[ReviewCard])
def get_review_cards(deck_id: int | None = None, db: Session = Depends(get_db)):
    """Получить карточки для повторения по SRS"""
    # Берём все карточки, у которых время следующего показа уже наступило
    query = db.query(models.Card).filter(models.Card.next_review <= datetime.utcnow())

    # Если передан deck_id — фильтруем по колоде
    if deck_id is not None:
        query = query.filter(models.Card.deck_id == deck_id)

    return query.all()


@router.post("/{card_id}/review", response_model=ReviewResponse)
def review_card(card_id: int, review: ReviewRequest, db: Session = Depends(get_db)):
    """Отправить ответ по карточке и получить новый интервал"""
    card = db.query(models.Card).filter(models.Card.id == card_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Карточка не найдена")

    from app.services.srs_service import SRSReview
    current_review = SRSReview(
        ease_factor=card.ease_factor,
        interval=card.interval,
        repetitions=card.repetitions
    )

    new_review = SRSService.calculate_next_review(review.quality, current_review)

    card.ease_factor = new_review.ease_factor
    card.interval = new_review.interval
    card.repetitions = new_review.repetitions
    card.next_review = new_review.next_review

    db.commit()
    db.refresh(card)

    return ReviewResponse(
        card_id=card.id,
        new_interval=card.interval,
        new_repetitions=card.repetitions,
        new_ease_factor=card.ease_factor,
        next_review=card.next_review
    )


@router.get("/deck/{deck_id}", response_model=list[CardResponse])
def get_deck_cards(deck_id: int, db: Session = Depends(get_db)):
    """Получить все карточки колоды"""
    cards = db.query(models.Card).filter(models.Card.deck_id == deck_id).all()
    return cards


@router.delete("/{card_id}")
def delete_card(card_id: int, db: Session = Depends(get_db)):
    card = db.query(models.Card).filter(models.Card.id == card_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Карточка не найдена")
    db.delete(card)
    db.commit()
    return {"message": "Карточка удалена"}