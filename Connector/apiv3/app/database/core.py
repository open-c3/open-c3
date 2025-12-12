# database/core.py
from typing import Dict, AsyncGenerator, Type, Optional
from sqlalchemy.ext.asyncio import (
    create_async_engine, 
    AsyncSession, 
    AsyncEngine,
    async_sessionmaker
)
from sqlalchemy.orm import declarative_base
from contextlib import asynccontextmanager
import logging
from ..config import settings

logger = logging.getLogger(__name__)

# 存储所有数据库的组件
class DatabaseRegistry:
    """数据库注册表"""
    
    def __init__(self):
        self.engines: Dict[str, AsyncEngine] = {}
        self.session_factories: Dict[str, async_sessionmaker] = {}
        self.bases: Dict[str, Type] = {}
        self.models: Dict[str, list] = {}  # 存储每个数据库的模型
        
    def register_base(self, db_name: str) -> Type:
        """为数据库注册Base类"""
        if db_name not in self.bases:
            self.bases[db_name] = declarative_base()
            self.models[db_name] = []
        return self.bases[db_name]
    
    def register_model(self, db_name: str, model_class: Type):
        """注册模型到指定数据库"""
        if db_name not in self.models:
            self.models[db_name] = []
        self.models[db_name].append(model_class)
    
    def get_base(self, db_name: str) -> Optional[Type]:
        """获取数据库的Base类"""
        return self.bases.get(db_name)
    
    def get_engine(self, db_name: str) -> Optional[AsyncEngine]:
        """获取数据库引擎"""
        return self.engines.get(db_name)
    
    def get_session_factory(self, db_name: str) -> Optional[async_sessionmaker]:
        """获取Session工厂"""
        return self.session_factories.get(db_name)


# 全局数据库注册表
registry = DatabaseRegistry()


class DatabaseManager:
    """数据库管理器"""
    
    def __init__(self):
        self.registry = registry
        
    async def init_databases(self):
        """初始化所有数据库连接"""
        logger.info("正在初始化数据库连接...")
        
        for db_name, db_url in settings.DATABASE_CONFIGS.items():
            try:
                # 创建引擎
                engine = create_async_engine(
                    db_url,
                    **settings.get_engine_options()
                )
                self.registry.engines[db_name] = engine
                
                # 创建Session工厂
                session_factory = async_sessionmaker(
                    engine,
                    class_=AsyncSession,
                    expire_on_commit=False
                )
                self.registry.session_factories[db_name] = session_factory
                
                # 注册Base类
                self.registry.register_base(db_name)
                
                logger.info(f"数据库 '{db_name}' 连接成功: {db_url}")
                
            except Exception as e:
                logger.error(f"数据库 '{db_name}' 连接失败: {e}")
                raise
    
    async def get_session(self, db_name: str) -> AsyncGenerator[AsyncSession, None]:
        """获取指定数据库的会话"""
        session_factory = self.registry.get_session_factory(db_name)
        if not session_factory:
            raise ValueError(f"数据库 '{db_name}' 未初始化或不存在")
        
        session = session_factory()
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
    
    async def init_tables(self, db_name: Optional[str] = None):
        """初始化数据库表
        
        Args:
            db_name: 数据库名称，为None时初始化所有数据库
        """
        if db_name:
            # 初始化指定数据库
            await self._init_single_database(db_name)
        else:
            # 初始化所有数据库
            logger.info("正在创建所有数据库表...")
            for name in self.registry.engines.keys():
                await self._init_single_database(name)
    
    async def _init_single_database(self, db_name: str):
        """初始化单个数据库的表"""
        engine = self.registry.get_engine(db_name)
        base = self.registry.get_base(db_name)
        
        if not engine or not base:
            logger.warning(f"数据库 '{db_name}' 未初始化，跳过表创建")
            return
        
        try:
            async with engine.begin() as conn:
                await conn.run_sync(base.metadata.create_all)
            logger.info(f"数据库 '{db_name}' 表创建成功")
        except Exception as e:
            logger.error(f"数据库 '{db_name}' 表创建失败: {e}")
            raise
    
    async def close(self):
        """关闭所有数据库连接"""
        logger.info("正在关闭数据库连接...")
        for name, engine in self.registry.engines.items():
            await engine.dispose()
            logger.info(f"数据库 '{name}' 连接已关闭")


# 创建全局数据库管理器实例
db_manager = DatabaseManager()


# 动态创建get_db函数
def create_get_db(db_name: str):
    """创建获取数据库会话的依赖函数"""
    async def get_db() -> AsyncGenerator[AsyncSession, None]:
        async for session in db_manager.get_session(db_name):
            yield session
    return get_db


# 自动为每个数据库创建get_db函数
for db_name in settings.DATABASE_NAMES:
    globals()[f"get_{db_name}_db"] = create_get_db(db_name)


# 快捷依赖函数
get_agent_db = create_get_db("agent")
get_job_db = create_get_db("job")
get_connector_db = create_get_db("connector")
get_jobx_db = create_get_db("jobx")
get_ci_db = create_get_db("ci")


# 快捷初始化函数
async def init_all_db():
    """初始化所有数据库"""
    return await db_manager.init_tables()

async def init_agent_db():
    """初始化Agent数据库"""
    return await db_manager.init_tables("agent")

async def init_job_db():
    """初始化Job数据库"""
    return await db_manager.init_tables("job")

async def init_connector_db():
    """初始化Connector数据库"""
    return await db_manager.init_tables("connector")

async def init_jobx_db():
    """初始化Jobx数据库"""
    return await db_manager.init_tables("jobx")

async def init_ci_db():
    """初始化Ci数据库"""
    return await db_manager.init_tables("ci")


def get_db_base(db_name: str):
    """获取指定数据库的Base类"""
    from .core import registry
    base = registry.get_base(db_name)
    if base is None:
        # 如果Base不存在，创建一个
        from sqlalchemy.orm import declarative_base
        base = declarative_base()
        registry.bases[db_name] = base
    return base


# 在适当的地方调用这个函数
def bind_all_models():
    """绑定所有模型到对应的Base"""
    import sys
    import inspect

    # 遍历所有已加载的模块
    for module_name, module in sys.modules.items():
        if module_name.startswith('app.models.'):
            for name, obj in inspect.getmembers(module):
                if inspect.isclass(obj) and hasattr(obj, '__database__'):
                    db_name = obj.__database__
                    base = registry.get_base(db_name)
                    if base:
                        # 修改类的父类
                        obj.__bases__ = (base,) + obj.__bases__[1:]
