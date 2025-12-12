from sqlalchemy import Column, Integer, String, DateTime, Text, JSON, Boolean
from datetime import datetime
from ..database.decorators import register_model
from ..database.core import get_db_base

Base = get_db_base("jobx")
#class Jobx(Base):
#    __tablename__ = "jobx"
#    
#    id = Column(Integer, primary_key=True, index=True)
#    name = Column(String(255), nullable=False, index=True)
#    description = Column(Text)
#    command = Column(Text, nullable=False)
#    parameters = Column(JSON, default=dict)
#    schedule = Column(String(100))  # cron表达式
#    status = Column(String(20), default="active")
#    last_run = Column(DateTime, nullable=True)
#    next_run = Column(DateTime, nullable=True)
#    created_at = Column(DateTime, default=datetime.utcnow)
#    
#    def __repr__(self):
#        return f"<Job(id={self.id}, name='{self.name}', status='{self.status}')>"
#
#
#class JobxExecution(Base):
#    __tablename__ = "jobx_executions"
#    
#    id = Column(Integer, primary_key=True, index=True)
#    job_id = Column(Integer, index=True)
#    status = Column(String(20))
#    output = Column(Text)
#    started_at = Column(DateTime)
#    completed_at = Column(DateTime, nullable=True)
#    created_at = Column(DateTime, default=datetime.utcnow)
