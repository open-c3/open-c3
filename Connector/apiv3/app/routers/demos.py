from fastapi import APIRouter, Request, Depends, HTTPException
from ..auth import auth


router = APIRouter(
    prefix="/demos",
    tags=["demos"],
    responses={404: {"description": "Not found"}},
)

fake_demos_db = {"plumbus": {"name": "Plumbus"}, "gun": {"name": "Portal Gun"}}

@router.get("/")
async def read_demos():
    return fake_demos_db

@router.get("/{item_id}")
async def read_item(item_id: str):
    if item_id not in fake_demos_db:
        raise HTTPException(status_code=404, detail="Demo not found")
    return {"name": fake_demos_db[item_id]["name"], "item_id": item_id}

@router.get("/auth/test")
@auth("openc3_agent_read","treeid",False)
async def auth_test(request: Request):
    return {"info": "Test Auth API", "stat": True}

@router.get("/auth/test_get_userinfo")
@auth("openc3_agent_read","treeid",True)
async def auth_test_get_userinfo(request: Request):
    username = getattr(request.state, "username", None)
    return {"info": "Test Auth API","stat": True, "username": username}
