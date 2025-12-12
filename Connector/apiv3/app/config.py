# config/settings.py
import os
from typing import Dict, List, Optional
from pydantic_settings import BaseSettings
from pydantic import Field, validator, root_validator
import urllib.parse


class Settings(BaseSettings):
    """应用设置"""

    # 数据库URL配置
    DATABASE_URL_CONNECTOR: str = Field(
        default="mysql+aiomysql://root:openc3123456^!@OPENC3_DB_IP:3306/connector?charset=utf8mb4",
        env="DATABASE_URL_CONNECTOR"
    )

    DATABASE_URL_AGENT: str = Field(
        default="mysql+aiomysql://root:openc3123456^!@OPENC3_DB_IP:3306/agent?charset=utf8mb4",
        env="DATABASE_URL_AGENT"
    )
    DATABASE_URL_JOB: str = Field(
        default="mysql+aiomysql://root:openc3123456^!@OPENC3_DB_IP:3306/jobs?charset=utf8mb4",
        env="DATABASE_URL_JOB"
    )

    DATABASE_URL_JOBX: str = Field(
        default="mysql+aiomysql://root:openc3123456^!@OPENC3_DB_IP:3306/jobx?charset=utf8mb4",
        env="DATABASE_URL_JOBX"
    )
    DATABASE_URL_CI: str = Field(
        default="mysql+aiomysql://root:openc3123456^!@OPENC3_DB_IP:3306/ci?charset=utf8mb4",
        env="DATABASE_URL_CI"
    )

    # 数据库引擎选项
    DB_ECHO: bool = Field(default=True, env="DB_ECHO")
    DB_POOL_SIZE: int = Field(default=20, env="DB_POOL_SIZE")
    DB_MAX_OVERFLOW: int = Field(default=10, env="DB_MAX_OVERFLOW")
    DB_POOL_TIMEOUT: int = Field(default=30, env="DB_POOL_TIMEOUT")
    DB_POOL_RECYCLE: int = Field(default=3600, env="DB_POOL_RECYCLE")
    DB_POOL_PRE_PING: bool = Field(default=True, env="DB_POOL_PRE_PING")

    # 其他配置

    # 这里并没有写死，".env"配置文件里面修改覆盖这里的配置
    APP_NAME: str = "FastAPI"
    HOST: str = "0.0.0.0"
    PORT: int = Field(default=7999, validation_alias="C3_APIV3_PORT")
    DEBUG: bool = True
    WORKERS: int = 2

    LOG_LEVEL: str =  "INFO"
    LOG_FILE: str = "logs/app.log"

    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(filename)s:%(lineno)d - %(message)s"

    @property
    def DATABASE_CONFIGS(self) -> Dict[str, str]:
        """获取所有数据库配置"""
        configs = {}

        # 自动收集所有以DATABASE_URL_开头的配置
        for key, value in self.dict().items():
            if key.startswith("DATABASE_URL_") and value:
                db_name = key.replace("DATABASE_URL_", "").lower()
                configs[db_name] = value

        return configs

    @property
    def DATABASE_NAMES(self) -> List[str]:
        """获取所有数据库名称"""
        return list(self.DATABASE_CONFIGS.keys())

    def get_engine_options(self) -> Dict:
        """获取引擎配置选项"""
        return {
            "echo": self.DB_ECHO,
            "pool_pre_ping": self.DB_POOL_PRE_PING,
            "pool_recycle": self.DB_POOL_RECYCLE,
            "pool_size": self.DB_POOL_SIZE,
            "max_overflow": self.DB_MAX_OVERFLOW,
            "pool_timeout": self.DB_POOL_TIMEOUT,
        }

    class Config:
        env_file = ".env"
        env_file_encoding = 'utf-8'
        case_sensitive = False


settings = Settings()
