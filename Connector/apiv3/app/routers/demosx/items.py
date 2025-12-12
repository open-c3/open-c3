from fastapi import FastAPI, HTTPException, Depends, APIRouter
from sqlalchemy import Column, Integer, String, Text, DateTime
from datetime import datetime
from sqlalchemy import Column, Integer, String, select
from pydantic import BaseModel
from typing import List
#from app.database import Base, get_db, init_db, AsyncSession
from sqlalchemy.ext.asyncio import AsyncSession
from app.database.core import get_db_base 
from app.database.core import get_jobx_db as get_db

Base = get_db_base("jobx")

# 定义数据库模型
class Item(Base):
    __tablename__ = "items"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), index=True)
    description = Column(String(500))
    created_at = Column(DateTime, default=datetime.utcnow)  # 可选：添加时间戳
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)  # 可选

# Pydantic模型用于请求和响应
class ItemCreate(BaseModel) :
    name: str
    description: str

class ItemResponse(BaseModel) :
    id: int
    name: str
    description: str

    class Config:
        from_attributes = True

router = APIRouter(
    prefix="/demos/items",
    tags=["items"],
    responses={404: {"description": "Not found"}},
)

# 创建数据
@router.post("/", response_model=ItemResponse)
async def create_item(item: ItemCreate, db: AsyncSession = Depends (get_db)):
    db_item = Item(name=item.name, description=item.description)
    db.add(db_item)
    await db.commit()
    await db.refresh(db_item)
    return db_item

# 查询数据
@router.get("/{item_id}", response_model=ItemResponse)
async def get_item(item_id:int, db: AsyncSession = Depends (get_db)):
    result = await db.execute(select(Item).filter(Item.id == item_id))
    item = result.scalars().first()
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return item

# 更新数据
@router.put("/{item_id}", response_model=ItemResponse)
async def update_item( item_id: int, updated_item: ItemCreate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Item).filter(Item.id == item_id))
    item = result.scalars().first()
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")

    item.name = updated_item.name
    item.description = updated_item.description
    await db.commit()
    await db.refresh(item)
    return item

# 删除数据
@router.delete("/{item_id}")
async def delete_item(item_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Item).filter(Item.id == item_id))
    item = result.scalars().first()
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found" )

    await db.delete(item)
    await db.commit()
    return {"message": "Item deleted successfully"}

# 批量创建数据
@router.post("/create_multiple_items/")
async def create_multiple_items(items: List[ItemCreate], db: AsyncSession = Depends(get_db)):
    async with db.begin():
        for item_data in items:
            db_item = Item (name=item_data.name, description=item_data.description)
            db.add(db_item)
    await db.commit()
    return {"message": "Items created successfully"}

# 获取所有数据
@router.get("/", response_model=List[ItemResponse] )
async def get_items(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Item))
    items = result.scalars().all()
    return items
