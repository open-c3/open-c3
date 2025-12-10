from fastapi import APIRouter, Request, Depends, HTTPException
import asyncio
from ..auth import auth
from typing import Optional, Dict, Any, Callable
import subprocess
from ..util.asyncx import run_command_async
import re
from functools import wraps
from fastapi import HTTPException, status, Request
from typing import Callable, Union, Tuple, Optional, Any

def validate(*args, **kwargs):
    """
    极简验证装饰器

    用法1: 字段名和规则交替
    @validate(
        "auth_point", r'^[a-z][a-z\d\-_]+$',
        "tree_id", r'^\d+$',
        "search_text", (r'^pattern$', True, "错误信息")
        "search_text2", (r'^pattern$', True)
    )

    用法2: 关键字参数
    @validate(
        auth_point=r'^[a-z][a-z\d\-_]+$',
        tree_id=(r'^\d+$', True, "必须是数字")
    )
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(request: Request, *args2, **kwargs2):
            # 构建规则字典
            rules = {}

            # 处理交替参数
            for i in range(0, len(args), 2):
                if i + 1 < len(args):
                    field = args[i]
                    rule = args[i + 1]
                    rules[field] = parse_rule(field, rule)

            # 处理关键字参数
            for field, rule in kwargs.items():
                rules[field] = parse_rule(rule)

            # 执行验证
            error = check_params(request, rules)
            if error:
                return {
                    "stat": False,
                    "info": f"check format fail {error}"
                }

            return await func(request, *args2, **kwargs2)
        return wrapper
    return decorator

def parse_rule(field: str,rule: Union[str, Tuple]) -> dict:
    """解析规则"""
    if isinstance(rule, tuple):
        if len(rule) == 2:
            pattern, required = rule
            error_msg = f"{field} format error {pattern}"
        elif len(rule) == 3:
            pattern, required, error_msg = rule
        else:
            raise ValueError("规则格式错误")
    else:
        pattern = rule
        required = True
        error_msg = None

    if isinstance(pattern, str):
        pattern = re.compile(pattern)

    return {
        "pattern": pattern,
        "required": required,
        "error_msg": error_msg
    }

def check_params(request: Request, rules: dict) -> Optional[str]:
    """检查参数"""
    for field, rule in rules.items():
        value = request.query_params.get(field)

        if rule["required"] and (value is None or value == ""):
            return f"字段 '{field}' 是必填的"

        if not rule["required"] and value in (None, ""):
            continue

        if value and not rule["pattern"].match(value):
            if rule["error_msg"]:
                return rule["error_msg"]
            return f"字段 '{field}' 格式无效: '{value}'"

    return None
