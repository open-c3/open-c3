from fastapi import APIRouter, Request, Depends, HTTPException
import asyncio
from ..auth import auth
from typing import Optional, Dict, Any, Callable
import subprocess
from ..util.asyncx import run_command_async
from ..util.formatcheck import validate
import re

router = APIRouter(
    prefix="/cmdb",
    tags=["cmdb"],
    responses={404: {"description": "Not found"}},
)

@router.get("/c3mc/device/search/history")
@validate(
    "search_text", (r'^[a-z\d][a-z\d\-_]+$', True, "搜索文本格式无效"),
)
@auth("openc3_agent_read","treeid",False)
async def c3mc_device_search_history(request: Request):
    """
    使用工具函数执行命令
    """
    search_text = request.query_params.get("search_text")
    username = getattr(request.state, "username", None)

    command = f"c3mc-device-search-history {search_text}"

    result = await run_command_async( command=command, shell=True, timeout=60 )

    if result["success"]:
        item = result["stdout"].split()

        filtered = [
            x for x in item
            if re.match(r'^\d+\-\d+$', x) or x == "curr"
        ]

        return {
            "stat": True,
            "data": [ { "name": i } for i in reversed(filtered) ]
        }
    else:
        return {
            "stat": False,
            "info": f"命令执行失败: {result.get('error', 'Unknown error')}",
        }
