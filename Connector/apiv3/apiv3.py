#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

from fastapi import FastAPI, Depends, HTTPException, Request, status, Query, Header, Cookie
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional, Dict, Any
import httpx
from datetime import datetime
import json

app = FastAPI()

class PermissionChecker:
    def __init__(self, required_permission: str):
        self.required_permission = required_permission

    async def __call__(
        self,
        request: Request,
        treeid: Optional[int] = Query(None, alias="treeid"),
        sid: Optional[str] = Cookie(None, alias="sid"),
        appname: Optional[str] = Header(None, alias="appname"),
        appkey: Optional[str] = Header(None, alias="appkey"),
    ):
        tree_id = treeid if treeid is not None else 0
        
        verify_data = {
            "auth_point": self.required_permission,
            "tree_id": tree_id
        }

        PERMISSION_API_URL = "http://api.agent.open-c3.org/PermissionChecker"

        try:
            async with httpx.AsyncClient() as client:

                headers = { "Content-Type": "application/json" }

                if appname:
                    headers["appname"] = appname
                if appkey:
                    headers["appkey"] = appkey

                cookies = {}
                if sid:
                    cookies["sid"] = sid

                response = await client.post(
                    PERMISSION_API_URL,
                    headers=headers,
                    cookies=cookies,
                    json=verify_data,
                    timeout=10.0
                )

                try:
                    result = response.json()
                except Exception as e:
                    raise HTTPException(
                        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                        info="Invalid response from permission service",
                        stat=False
                    )

                if not isinstance(result, dict) or 'stat' not in result:
                    raise HTTPException(
                        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                        info="Invalid response format from permission service",
                        stat=False
                    )

                if not result['stat']:
                    error_info = result.get('info', 'No error info provided')
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        info=f"Permission denied: {error_info}",
                        stat=False
                    )

                if 'data' not in result:
                    raise HTTPException(
                        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                        info="Missing data field in permission response",
                        stat=False
                    )

                if result['data'] != 1:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        info="noauth",
                        stat=False
                    )

                return {
                    "stat": True,
                    "info": "Success"
                }

        except httpx.ConnectError as e:
            return {
                "stat": False,
                "info": "Service is unavailable"
            }

        except httpx.TimeoutException as e:
            raise HTTPException(
                status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                info="Permission service timeout",
                stat=False
            )

        except httpx.RequestError as e:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                info=f"Permission service error: {str(e)}",
                stat=False
            )
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                info=f"Internal server error: {str(e)}",
                stat=False
            )

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = datetime.now()

    request_info = {
        "method": request.method,
        "path": request.url.path,
        "query_params": dict(request.query_params),
        "headers": {k: v for k, v in request.headers.items()},
        "cookies": request.cookies,
        "time": start_time.isoformat()
    }

    safe_headers = {}
    for k, v in request_info["headers"].items():
        if k.lower() in ["appkey"]:
            safe_headers[k] = f"{v[:10]}..."  # 只显示部分appkey
        else:
            safe_headers[k] = v

    print("\n" + "="*60)
    print(f"[请求开始] {request_info['time']} {request_info['method']} {request_info['path']}")
    print(f"查询参数: {request_info['query_params']}")
    print(f"请求头: {json.dumps(safe_headers, indent=2, ensure_ascii=False)}")
    print(f"Cookies: {request_info['cookies']}")
    print("="*60)

    response = await call_next(request)

    process_time = (datetime.now() - start_time).total_seconds()
    print(f"[请求结束] 耗时: {process_time:.3f}s 状态码: {response.status_code}")

    return response

@app.get("/test/foo")
async def test_foo(
    treeid: int = Query(..., description="Tree ID"),
    permission_data: dict = Depends(PermissionChecker("openc3_agent_read"))
):
    return { "stat": True, "info": "Success" }

@app.get("/health")
async def health():
    return {"stat": True, "timestamp": datetime.now().isoformat()}


