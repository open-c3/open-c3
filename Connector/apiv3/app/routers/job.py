from fastapi import APIRouter, Request, Depends, HTTPException
from sqlalchemy import text
import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from app.auth import auth
from typing import Optional, Dict, Any, Callable
import subprocess
import re
from app.database.core import get_job_db

router = APIRouter(
    prefix="/job",
    tags=["job"],
    responses={404: {"description": "Not found"}},
)

@router.get("/keepalive")
@auth("openc3_job_read","treeid",False)
async def get_jobs(request: Request, db: AsyncSession = Depends(get_job_db)):
    result = await db.execute(text("SELECT * FROM openc3_job_keepalive"))
    jobs = result.mappings().all()
    return {"stat": True, "data": jobs}

@router.get("/keepalive/count")
@auth("openc3_job_read","treeid",False)
async def count_jobs(request: Request, db: AsyncSession = Depends(get_job_db)):
    result = await db.execute(text("SELECT COUNT(*) as count FROM openc3_job_keepalive"))
    count = result.scalar()
    return {"stat": True, "data": count}


