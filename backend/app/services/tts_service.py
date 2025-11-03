import os
import uuid
from google.cloud import texttospeech
from fastapi import HTTPException
from app.services.file_service import file_service

class TTSService:
    def __init__(self):
        self.client = None
        self._initialize_client()
    
    def _initialize_client(self):
        """Инициализирует клиент Google Cloud TTS"""
        try:
            # Для работы нужен credentials файл Google Cloud
            # Можно установить переменную окружения GOOGLE_APPLICATION_CREDENTIALS
            self.client = texttospeech.TextToSpeechClient()
        except Exception as e:
            print(f"Предупреждение: Google Cloud TTS не инициализирован: {e}")
            self.client = None
    
    async def generate_speech(self, text: str, language_code: str = "ru-RU") -> str:
        """Генерирует аудио из текста и возвращает путь к файлу"""
        if not self.client:
            raise HTTPException(
                status_code=501, 
                detail="TTS сервис недоступен. Проверьте настройки Google Cloud."
            )
        
        if len(text) > 5000:
            raise HTTPException(status_code=400, detail="Текст слишком длинный (макс. 5000 символов)")
        
        try:
            # Настройка синтеза речи
            synthesis_input = texttospeech.SynthesisInput(text=text)
            
            voice = texttospeech.VoiceSelectionParams(
                language_code=language_code,
                ssml_gender=texttospeech.SsmlVoiceGender.NEUTRAL
            )
            
            audio_config = texttospeech.AudioConfig(
                audio_encoding=texttospeech.AudioEncoding.MP3
            )
            
            # Запрос на синтез речи
            response = self.client.synthesize_speech(
                input=synthesis_input,
                voice=voice,
                audio_config=audio_config
            )
            
            # Сохраняем аудио файл
            filename = f"{uuid.uuid4()}.mp3"
            file_path = os.path.join(file_service.audio_dir, filename)
            
            with open(file_path, "wb") as out:
                out.write(response.audio_content)
            
            return f"/uploads/audio/{filename}"
            
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Ошибка TTS: {str(e)}")
    
    def is_available(self) -> bool:
        """Проверяет доступность TTS сервиса"""
        return self.client is not None

tts_service = TTSService()
