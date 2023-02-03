# 监控采集器/elasticsearch

# 测试容器

docker run -d -p 9200:9200 -p 9300:9300 -e ES_JAVA_POTS="-Xms128m -Xmx128m" -e "discovery.type=single-node" elasticsearch:7.8.0

# 配置文件

### 无密码
```
url: http://10.10.1.1:9200
```

## 有密码
```
url: 'http://admin:pass@localhost:9200'
```

注：
```
格式为：<proto>://<user>:<password>@<host>:<port>
如该有特殊字符，需要url格式转码
```

grafana dashboard
```
https://grafana.com/grafana/dashboards/6483
```
