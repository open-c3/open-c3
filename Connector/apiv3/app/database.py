from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base
from .config import settings

# 创建异步引擎
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=True,# 打印SQL语句
    pool_pre_ping=True, # 连接池预检查
    pool_recycle=3600, # 连接回收时间
)

# 创建异步Session类
AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)
# 创建基类
Base = declarative_base()

# 获取数据库会话的依赖函数
async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

# 初始化数据库函数
async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
