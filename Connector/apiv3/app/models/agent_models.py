from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text
from datetime import datetime

from ..database.core import get_db_base

Base = get_db_base("agent")

# 使用装饰器注册模型到agent数据库
#class Agent(Base):
#    __tablename__ = "agents"
#    
#    id = Column(Integer, primary_key=True, index=True)
#    name = Column(String(255), unique=True, index=True)
#    host = Column(String(100))
#    port = Column(Integer)
#    status = Column(String(20), default="offline")
#    last_seen = Column(DateTime, nullable=True)
#    created_at = Column(DateTime, default=datetime.utcnow)
#    
#    def __repr__(self):
#        return f"<Agent(id={self.id}, name='{self.name}', status='{self.status}')>"
#
#
#class AgentTask(Base):
#    __tablename__ = "temp_agent_tasks_001"
#    
#    id = Column(Integer, primary_key=True, index=True)
#    agent_id = Column(Integer, index=True)
#    command = Column(Text, nullable=False)
#    status = Column(String(20), default="pending")
#    result = Column(Text)
#    created_at = Column(DateTime, default=datetime.utcnow)
#    completed_at = Column(DateTime, nullable=True)
