# 集群版部署

```
把第一台的数据库3306端口打开,/data/open-c3/Installer/C3/docker-compose.yml 

添加文件: /data/open-c3/Connector/mysql.config-test 
---
host: 10.10.10.10
#username: root
#password: '123456'
#port: 3306
#database: openc3

添加文件: /data/open-c3-data/.open-c3.hostname 
openc3-srv-docker-002

修改文件: /data/open-c3/Connector/tt/trouble-ticketing/cfg.json 
修改数据库地址: OPENC3_DB_IP 到10.10.10.10

拷贝agent的key到第二台机器： /data/open-c3-data/auth/*
```
