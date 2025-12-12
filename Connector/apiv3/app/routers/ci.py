from fastapi import APIRouter, Request, Depends, HTTPException
from sqlalchemy import text
import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from app.auth import auth
from typing import Optional, Dict, Any, Callable
import subprocess
import re
from app.database.core import get_ci_db

router = APIRouter(
    prefix="/ci",
    tags=["ci"],
    responses={404: {"description": "Not found"}},
)

@router.get("/keepalive")
@auth("openc3_ci_read","treeid",False)
async def get_cis(request: Request, db: AsyncSession = Depends(get_ci_db)):
    result = await db.execute(text("SELECT * FROM openc3_ci_keepalive"))
    cis = result.mappings().all()
    return {"stat": True, "data": cis}

@router.get("/keepalive/count")
@auth("openc3_ci_read","treeid",False)
async def count_cis(request: Request, db: AsyncSession = Depends(get_ci_db)):
    result = await db.execute(text("SELECT COUNT(*) as count FROM openc3_ci_keepalive"))
    count = result.scalar()
    return {"stat": True, "data": count}


