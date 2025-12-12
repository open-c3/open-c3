import logging
import logging.config
import os
from pathlib import Path
import sys
from app.config import settings

def setup_logging():
    """
    设置应用的日志配置

    通过环境变量控制：
    - LOG_LEVEL: 日志级别 (DEBUG, INFO, WARNING, ERROR)
    - LOG_FILE: 日志文件路径
    - LOG_FORMAT: 日志格式
    """

    # 获取配置
    log_level = settings.LOG_LEVEL
    log_file = settings.LOG_FILE

    # 创建日志目录
    log_dir = Path(log_file).parent
    log_dir.mkdir(parents=True, exist_ok=True)

    # 日志格式
    log_format = settings.LOG_FORMAT

    # 配置字典
    config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "default": {
                "format": log_format,
                "datefmt": "%Y-%m-%d %H:%M:%S"
            },
            "simple": {
                "format": "%(asctime)s - %(levelname)s - %(message)s"
            }
        },
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "level": log_level,
                "formatter": "default",
                "stream": sys.stdout
            },
            "file": {
                "class": "logging.handlers.RotatingFileHandler",
                "level": log_level,
                "formatter": "default",
                "filename": log_file,
                "maxBytes": 10 * 1024 * 1024,  # 10MB
                "backupCount": 5,
                "encoding": "utf8"
            }
        },
        "root": {
            "level": log_level,
            "handlers": ["console", "file"]
        },
        "loggers": {
            "uvicorn": {
                "level": "INFO",
                "handlers": ["console"],
                "propagate": False
            },
            "uvicorn.access": {
                "level": "INFO",
                "handlers": ["console"],
                "propagate": False
            },
            "uvicorn.error": {
                "level": "INFO"
            }
        }
    }

    # 应用配置
    logging.config.dictConfig(config)

    # 获取根logger并记录配置完成
    logger = logging.getLogger(__name__)
    logger.info(f"日志系统初始化完成，级别: {log_level}")

    return logger

# 导出get_logger函数
def get_logger(name: str = None) -> logging.Logger:
    """
    获取logger实例

    Args:
        name: logger名称，通常是 __name__

    Returns:
        logging.Logger实例
    """
    return logging.getLogger(name)
