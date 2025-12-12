from fastapi import Depends, FastAPI, HTTPException, Request, status
from functools import wraps
from typing import Callable, Any
import inspect
import httpx

app = FastAPI()

def auth(permission: str, treeid_param_name: str = "treeid",get_userinfo: bool=False):
    """
    Help:
    @app.get("/path")
    @auth("openc3_agent_read") # or @auth("openc3_agent_read","treeid") or @auth("openc3_agent_read",None)
    async def endpoint(request: Request):
        return {"message": "Success"}

    @app.get("/path")
    @auth("openc3_agent_read","treeid",True)
    async def protected_endpoint(request: Request):
        username = getattr(request.state, "username", None)
        return {"info": "Test Auth API","username": username}

    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(request: Request, *args, **kwargs) -> Any:
            treeid_str = request.query_params.get(treeid_param_name, "0")
            try:
                treeid = int(treeid_str) if treeid_str.isdigit() else 0
            except:
                treeid = 0

            appname = request.headers.get("appname")
            appkey = request.headers.get("appkey")
            sid = request.cookies.get("sid")

            verify_data = {
                "auth_point": permission,
                "tree_id": treeid,
                "get_userinfo": get_userinfo
            }

            PERMISSION_API_URL = "http://api.agent.open-c3.org/PermissionChecker"

            try:
                async with httpx.AsyncClient() as client:
                    headers = {"Content-Type": "application/json"}
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


                    if response.status_code != 200:
                        return {
                            "stat": False,
                            "info": "PermissionChecker API Error, status code not 200"
                        }

                    result = response.json()
                    if result.get("code") == 10000:
                        return {
                            "stat": False,
                            "code": 10000,
                        }

                    if not result.get("stat"):
                        return {
                            "stat": False,
                            "info": result.get("info", "PermissionChecker stat is false")
                        }

                    if result.get("data") != 1:
                        return {
                            "stat": False,
                            "info": "No permission"
                        }

                    request.state.username = result.get("username","unknow")

                    return await func(request, *args, **kwargs)

            except httpx.ConnectError as e:
                return {
                    "stat": False,
                    "info": f"PermissionChecker API ConnectError: {str(e)}"
                }

            except httpx.RequestError as e:
                return {
                    "stat": False,
                    "info": f"PermissionChecker API RequestError: {str(e)}"
                }

        return wrapper
    return decorator

