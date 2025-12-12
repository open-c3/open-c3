#!/data/Software/mydan/python3/bin/python3

import uvicorn
from app.config import settings

if __name__ == "__main__":
    uvicorn. run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        workers=settings.WORKERS,
        log_level=settings.LOG_LEVEL.lower()
    )
