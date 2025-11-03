from datetime import datetime, timedelta
from dataclasses import dataclass
from typing import Optional

@dataclass
class SRSReview:
    ease_factor: float = 2.5
    interval: int = 0
    repetitions: int = 0
    next_review: Optional[datetime] = None

class SRSService:
    """Сервис для алгоритма интервального повторения SM-2"""
    
    @staticmethod
    def calculate_next_review(quality: int, current_review: SRSReview) -> SRSReview:
        """
        Алгоритм SM-2 для расчета следующего повторения
        
        quality: 0-5, где:
          0 - Совсем не помню
          1 - Очень трудно
          2 - Трудно  
          3 - Нормально
          4 - Легко
          5 - Очень легко
        """
        
        if quality < 3:
            # Неправильный ответ - сбрасываем прогресс
            current_review.repetitions = 0
            current_review.interval = 1
        else:
            # Правильный ответ
            if current_review.repetitions == 0:
                current_review.interval = 1
            elif current_review.repetitions == 1:
                current_review.interval = 6
            else:
                current_review.interval = round(current_review.interval * current_review.ease_factor)
            
            current_review.repetitions += 1
        
        # Обновление ease factor
        current_review.ease_factor += (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
        current_review.ease_factor = max(1.3, current_review.ease_factor)
        
        # Расчет следующего повторения
        current_review.next_review = datetime.now() + timedelta(days=current_review.interval)
        
        return current_review
    
    @staticmethod
    def get_default_review() -> SRSReview:
        """Возвращает настройки по умолчанию для новой карточки"""
        return SRSReview(
            ease_factor=2.5,
            interval=0,
            repetitions=0,
            next_review=datetime.now()
        )
