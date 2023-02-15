# 监控/mongodb不同的exporter说明

## amazonaws/mongodb_exporter
```
端口 9001

镜像: amazonaws/mongodb_exporter

启动参数 -mongodb.collect.collection -mongodb.collect.connpoolstats -mongodb.collect.database -mongodb.collect.oplog -mongodb.collect.profile -mongodb.collect.replset -mongodb.collect.top

对应看版: MongoDB
https://grafana.com/grafana/dashboards/12079-mongodb/
高版本报错： https://blog.csdn.net/weixin_50231020/article/details/123237962
```

## percona/mongodb_exporter
```
git : https://github.com/percona/mongodb_exporter
镜像: percona/mongodb_exporter:0.35

端口:  9216
启动参数 ： --collect-all

支持高版本；
对应看板: General / Opstree/Mongodb Dashboard
https://grafana.com/grafana/dashboards/16490-opstree-mongodb-dashboard/
```
