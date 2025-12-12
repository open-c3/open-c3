from sqlalchemy import Column, Integer, String, DateTime, Text, JSON
from datetime import datetime
from ..database.decorators import register_model
from ..database.core import get_db_base

Base = get_db_base("connector")
#class Connector(Base):
#    __tablename__ = "connectors"
#    
#    id = Column(Integer, primary_key=True, index=True)
#    name = Column(String(255), unique=True, index=True)
#    type = Column(String(50))  # mysql, postgresql, redis, kafka等
#    config = Column(JSON, nullable=False)  # 连接配置
#    status = Column(String(20), default="inactive")
#    last_check = Column(DateTime, nullable=True)
#    created_at = Column(DateTime, default=datetime.utcnow)
#    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
#    
#    def __repr__(self):
#        return f"<Connector(id={self.id}, name='{self.name}', type='{self.type}')>"
#
#
#class ConnectionLog(Base):
#    __tablename__ = "connection_logs"
#    
#    id = Column(Integer, primary_key=True, index=True)
#    connector_id = Column(Integer, index=True)
#    action = Column(String(50))  # connect, disconnect, query, etc.
#    status = Column(String(20))
#    details = Column(JSON)
#    duration = Column(Integer)  # 毫秒
#    created_at = Column(DateTime, default=datetime.utcnow, index=True)
