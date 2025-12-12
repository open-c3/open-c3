from fastapi import APIRouter, Request, Depends, HTTPException
from sqlalchemy import text
import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from app.auth import auth
from typing import Optional, Dict, Any, Callable
import subprocess
import re
from app.database.core import get_connector_db

router = APIRouter(
    prefix="/connector",
    tags=["connector"],
    responses={404: {"description": "Not found"}},
)

@router.get("/keepalive")
@auth("openc3_connector_read","treeid",False)
async def get_connectors(request: Request, db: AsyncSession = Depends(get_connector_db)):
    result = await db.execute(text("SELECT * FROM openc3_connector_keepalive"))
    connectors = result.mappings().all()
    return {"stat": True, "data": connectors}

@router.get("/keepalive/count")
@auth("openc3_connector_read","treeid",False)
async def count_connectors(request: Request, db: AsyncSession = Depends(get_connector_db)):
    result = await db.execute(text("SELECT COUNT(*) as count FROM openc3_connector_keepalive"))
    count = result.scalar()
    return {"stat": True, "data": count}


