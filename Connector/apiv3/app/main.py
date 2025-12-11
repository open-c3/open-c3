from fastapi import FastAPI
from .routers import demos, cmdb
from .routers.demosx import items
from .database import Base, get_db, init_db, AsyncSession

app = FastAPI(root_path="/api/v3")

@app.on_event("startup")
async def on_startup():
    await init_db()

app.include_router(demos.router)
app.include_router(cmdb.router)
app.include_router(items.router)

@app.get("/health")
async def health():
    return {"stat": True, "info": "This is Open-C3 API V3, I'm ok now" }


