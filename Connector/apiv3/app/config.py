import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # 数据库配置 - 使用SQLite进行演示
    DATABASE_URL: str = "sqlite+aiosqlite:///./test.db"

    # FastAPI配置
    APP_NAME: str = "FastAPI Async SQLAlchemy Demo"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True

    # 服务器配置
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    class Config:
        env_file = ".env"
# 创建设置实例

settings = Settings()
