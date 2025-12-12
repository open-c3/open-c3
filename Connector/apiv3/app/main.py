# main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import logging
from app.routers import demos, cmdb, connector, agent, job, jobx, ci
from .routers.demosx import items

from .database.core import (
    db_manager,
    get_connector_db,
    get_agent_db,
    get_job_db,
    get_jobx_db,
    get_ci_db,
    init_all_db,
    init_connector_db,
    init_agent_db,
    init_job_db,
    init_jobx_db,
    init_ci_db
)
#from .models.agent_models import Agent, AgentTask
#from .models.job_models import Job, JobExecution
#from .models.jobx_models import Jobx, JobxExecution
#from .models.ci_models import Ci, CiExecution
#from .models.connector_models import Connector, ConnectionLog

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时
    logger.info("应用启动中...")

    # 初始化所有数据库连接
    await db_manager.init_databases()

    # 可以选择性初始化表
    await init_all_db()  # 初始化所有表
    # 或只初始化部分
    # await init_connector_db()
    # await init_agent_db()
    # await init_job_db()
    # await init_jobx_db()
    # await init_ci_db()

    logger.info("数据库初始化完成")

    yield

    # 关闭时
    logger.info("应用关闭中...")
    await db_manager.close()
    logger.info("数据库连接已关闭")

app = FastAPI(
    title="Open-C3 API V3",
    description="Open-C3 API V3",
    version="1.0.0",
    lifespan=lifespan,
    #root_path="/api/v3"
)

app.include_router(demos.router)
app.include_router(cmdb.router)
app.include_router(connector.router)
app.include_router(agent.router)
app.include_router(job.router)
app.include_router(jobx.router)
app.include_router(ci.router)
app.include_router(items.router)

@app.get("/")
async def root():
    """根路由"""
    return {
        "stat": True,
        "info": "Open-C3",
        "data": {
            "databases": list(db_manager.registry.engines.keys()),
            "total_connections": len(db_manager.registry.engines)
        }
    }

@app.get("/health")
async def health_check():
    """健康检查 - 检查所有数据库连接"""
    health_status = {}

    for db_name, engine in db_manager.registry.engines.items():
        try:
            async with engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
                health_status[db_name] = "healthy"
        except Exception as e:
            health_status[db_name] = f"unhealthy: {str(e)}"

    all_healthy = all(status == "healthy" for status in health_status.values())

    return {
        "stat": True,
        "info": "healthy" if all_healthy else "unhealthy",
        "data": { "databases": health_status }
    }
