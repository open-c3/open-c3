from fastapi import APIRouter, Request, Depends, HTTPException
import asyncio
from ..auth import auth
from typing import Optional, Dict, Any, Callable
import subprocess

async def run_command_async(
    command: str,
    shell: bool = False,
    timeout: Optional[int] = 30,
    encoding: str = "utf-8"
) -> Dict[str, Any]:
    """
    异步执行命令的工具函数

    Args:
        command: 要执行的命令
        shell: 是否使用shell执行
        timeout: 超时时间（秒），None表示不超时
        encoding: 输出编码

    Returns:
        包含执行结果的字典
    """
    try:
        if shell:
            # 使用shell执行
            process = await asyncio.create_subprocess_shell(
                command,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
        else:
            # 不使用shell，更安全
            args = shlex.split(command)
            process = await asyncio.create_subprocess_exec(
                *args,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )

        # 执行命令
        if timeout is not None:
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(),
                    timeout=timeout
                )
            except asyncio.TimeoutError:
                # 超时处理
                try:
                    process.terminate()
                    await asyncio.sleep(1)
                    if process.returncode is None:
                        process.kill()
                except:
                    pass

                return {
                    "success": False,
                    "error": f"Command execution timeout ({timeout} second)",
                    "command": command,
                    "returncode": None,
                    "stdout": "",
                    "stderr": ""
                }
        else:
            stdout, stderr = await process.communicate()

        # 解码输出
        stdout_str = stdout.decode(encoding, errors="ignore") if stdout else ""
        stderr_str = stderr.decode(encoding, errors="ignore") if stderr else ""

        return {
            "success": process.returncode == 0,
            "command": command,
            "returncode": process.returncode,
            "stdout": stdout_str,
            "stderr": stderr_str
        }

    except FileNotFoundError:
        return {
            "success": False,
            "error": f"Command not found: {command.split()[0] if not shell else command}",
            "command": command,
            "returncode": None,
            "stdout": "",
            "stderr": ""
        }
    except Exception as e:
        return {
            "success": False,
            "error": f"Command run fail: {str(e)}",
            "command": command,
            "returncode": None,
            "stdout": "",
            "stderr": ""
        }



