from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from fastapi.responses import FileResponse
import os
from app.services.file_service import file_service
from app.services.tts_service import tts_service
from app.schemas.card import TTSRequest, TTSResponse

router = APIRouter()

@router.post("/upload/image/")
async def upload_image(file: UploadFile = File(...)):
    """Загружает изображение"""
    try:
        file_url = await file_service.save_image(file)
        return {
            "filename": file.filename,
            "url": file_url,
            "message": "Изображение успешно загружено"
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/upload/audio/")
async def upload_audio(file: UploadFile = File(...)):
    """Загружает аудио файл"""
    try:
        file_url = await file_service.save_audio(file)
        return {
            "filename": file.filename,
            "url": file_url,
            "message": "Аудио файл успешно загружен"
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/tts/generate", response_model=TTSResponse)
async def generate_tts(tts_request: TTSRequest):
    """Генерирует аудио из текста с помощью TTS"""
    try:
        audio_url = await tts_service.generate_speech(
            tts_request.text, 
            tts_request.language_code
        )
        
        return TTSResponse(
            audio_url=audio_url,
            text=tts_request.text,
            language_code=tts_request.language_code
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/files/{file_path:path}")
async def get_file(file_path: str):
    """Возвращает файл по его пути"""
    full_path = file_service.get_file_path(file_path)
    
    if not os.path.exists(full_path):
        raise HTTPException(status_code=404, detail="Файл не найден")
    
    return FileResponse(full_path)

@router.get("/tts/status")
async def get_tts_status():
    """Проверяет статус TTS сервиса"""
    return {
        "available": tts_service.is_available(),
        "service": "Google Cloud Text-to-Speech"
    }
