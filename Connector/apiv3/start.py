#!/data/Software/mydan/python3/bin/python3
# start_fixed.py

import os
import sys
import multiprocessing
import subprocess
from app.config import settings

class ServerStarter:
    """服务器启动器"""
    
    def __init__(self):
        self.config = self._load_config()
        
    def _load_config(self):
        """加载配置"""
        return {
            "app": "app.main:app",
            "host": settings.HOST,
            "port": settings.PORT,
            "log_level": settings.LOG_LEVEL.lower(),
            "debug": settings.DEBUG,
        }
    
    def get_workers(self):
        """获取 worker 数量"""
        if hasattr(settings, 'WORKERS') and settings.WORKERS:
            return settings.WORKERS
        
        cpu_count = multiprocessing.cpu_count()
        if self.config["debug"]:
            return 1  # 开发模式单进程
        else:
            return min(cpu_count * 2, 8)  # 生产模式最多8个
    
    def should_use_gunicorn(self):
        """判断是否使用 Gunicorn"""
        # 1. 环境变量强制指定
        server_type = os.getenv("SERVER_TYPE", "").lower()
        if server_type == "gunicorn":
            return True
        if server_type == "uvicorn":
            return False
        
        # 2. 开发模式用 Uvicorn（支持热重载）
        if self.config["debug"]:
            return False
        
        # 3. 生产模式用 Gunicorn（如果有安装）
        try:
            import gunicorn
            return True
        except ImportError:
            return False
    
    def print_startup_info(self):
        """打印启动信息"""
        workers = self.get_workers()
        use_gunicorn = self.should_use_gunicorn()
        
        print("=" * 60)
        print("服务器启动配置")
        print("=" * 60)
        print(f"应用模块: {self.config['app']}")
        print(f"监听地址: {self.config['host']}:{self.config['port']}")
        print(f"日志级别: {self.config['log_level']}")
        print(f"调试模式: {self.config['debug']}")
        print(f"Worker 数量: {workers}")
        print(f"服务器类型: {'Gunicorn + Uvicorn' if use_gunicorn else 'Uvicorn'}")
        print("=" * 60)
        print()
    
    def start_uvicorn(self):
        """启动 Uvicorn"""
        import uvicorn
        
        uvicorn_config = {
            "app": self.config["app"],
            "host": self.config["host"],
            "port": self.config["port"],
            "log_level": self.config["log_level"],
        }
        
        if self.config["debug"]:
            uvicorn_config["reload"] = True
            uvicorn_config["reload_dirs"] = ["app"]
            uvicorn_config["reload_delay"] = 0.25
        else:
            workers = self.get_workers()
            if workers > 1:
                uvicorn_config["workers"] = workers
        
        uvicorn.run(**uvicorn_config)
    
    def start_gunicorn(self):
        """启动 Gunicorn - 修复参数错误"""
        workers = self.get_workers()
        
        # 基础命令
        cmd = [
            sys.executable, "-m", "gunicorn",
            self.config["app"],
            "--bind", f"{self.config['host']}:{self.config['port']}",
            "--workers", str(workers),
            "--worker-class", "uvicorn.workers.UvicornWorker",
            "--access-logfile", "-",
            "--error-logfile", "-",
            "--log-level", self.config["log_level"],
        ]
        
        # 添加常用参数（使用正确的参数名）
        cmd.extend([
            "--timeout", "120",
            "--keep-alive", "5", 
            "--max-requests", "1000",
            "--max-requests-jitter", "50",
        ])
        
        if self.config["debug"]:
            cmd.extend(["--reload"])
        
        # 添加自定义配置
        if hasattr(settings, 'GUNICORN_EXTRA_ARGS'):
            extra_args = settings.GUNICORN_EXTRA_ARGS.split()
            cmd.extend(extra_args)
        
        print(f"执行命令: {' '.join(cmd)}")
        
        # 执行
        os.execvp(cmd[0], cmd)
    
    def start(self):
        """启动服务器"""
        self.print_startup_info()
        
        if self.should_use_gunicorn():
            self.start_gunicorn()
        else:
            self.start_uvicorn()

if __name__ == "__main__":
    starter = ServerStarter()
    starter.start()
