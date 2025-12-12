from typing import Type
from functools import wraps
from ..database.core import registry

def register_model(db_name: str):
    """注册模型到指定数据库的装饰器"""
    def decorator(model_class):
        # 标记这个类属于哪个数据库
        model_class.__database__ = db_name
        return model_class
    return decorator
