from fastapi import FastAPI
from .routers import demos

app = FastAPI()

app.include_router(demos.router)

@app.get("/health")
async def health():
    return {"stat": True, "info": "This is Open-C3 API V3, I'm ok now" }


