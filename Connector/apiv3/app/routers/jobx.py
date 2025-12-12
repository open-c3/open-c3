from fastapi import APIRouter, Request, Depends, HTTPException
from sqlalchemy import text
import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from app.auth import auth
from typing import Optional, Dict, Any, Callable
import subprocess
import re
from app.database.core import get_jobx_db

router = APIRouter(
    prefix="/jobx",
    tags=["jobx"],
    responses={404: {"description": "Not found"}},
)

@router.get("/keepalive")
@auth("openc3_jobx_read","treeid",False)
async def get_jobxs(request: Request, db: AsyncSession = Depends(get_jobx_db)):
    result = await db.execute(text("SELECT * FROM openc3_jobx_keepalive"))
    jobxs = result.mappings().all()
    return {"stat": True, "data": jobxs}

@router.get("/keepalive/count")
@auth("openc3_jobx_read","treeid",False)
async def count_jobxs(request: Request, db: AsyncSession = Depends(get_jobx_db)):
    result = await db.execute(text("SELECT COUNT(*) as count FROM openc3_jobx_keepalive"))
    count = result.scalar()
    return {"stat": True, "data": count}


