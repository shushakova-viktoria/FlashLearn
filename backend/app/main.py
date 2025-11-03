from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.core.config import settings

app = FastAPI(
    title="FlashLearn API",
    description="Backend для системы интервального повторения с Flutter фронтендом",
    version="0.2.0"
)

# CORS для Flutter - разрешаем всё
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,  # ["*"] для Flutter
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Статические файлы
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

# Импортируем и подключаем роутеры
from app.api.endpoints import users, decks, cards, media

app.include_router(users.router, prefix=settings.API_V1_PREFIX, tags=["users"])
app.include_router(decks.router, prefix=settings.API_V1_PREFIX, tags=["decks"])
app.include_router(cards.router, prefix=settings.API_V1_PREFIX, tags=["cards"])
app.include_router(media.router, prefix=settings.API_V1_PREFIX, tags=["media"])

@app.get("/")
async def root(request: Request):  # ← Добавьте Request параметр
    base_url = str(request.base_url)
    return {
        "message": "🚀 FlashLearn API с Flutter фронтендом работает!",
        "docs": "/docs",
        "media_url": f"{base_url}uploads"  # ← Динамический URL
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "debug": settings.DEBUG}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )

print("✅ Все роутеры подключены! Сервер запущен.")
