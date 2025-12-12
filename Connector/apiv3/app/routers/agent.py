from fastapi import APIRouter, Request, Depends, HTTPException
from sqlalchemy import text
import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from app.auth import auth
from typing import Optional, Dict, Any, Callable
import subprocess
import re
from app.database.core import get_agent_db

router = APIRouter(
    prefix="/agent",
    tags=["agent"],
    responses={404: {"description": "Not found"}},
)

@router.get("/keepalive")
@auth("openc3_agent_read","treeid",False)
async def get_agents(request: Request, db: AsyncSession = Depends(get_agent_db)):
    result = await db.execute(text("SELECT * FROM openc3_agent_keepalive"))
    agents = result.mappings().all()
    return {"stat": True, "data": agents}

@router.get("/keepalive/count")
@auth("openc3_agent_read","treeid",False)
async def count_agents(request: Request, db: AsyncSession = Depends(get_agent_db)):
    result = await db.execute(text("SELECT COUNT(*) as count FROM openc3_agent_keepalive"))
    count = result.scalar()
    return {"stat": True, "data": count}
