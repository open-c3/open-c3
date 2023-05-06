# 监控/blackbox

## 操作步骤
```
如果你需要黑盒测试，比如测试url的监控状态，https的证书是否过期。
可以按照下面步骤进行操作。

1. 开启黑盒监控的功能

/data/open-c3/AGENT/monitor/blackbox-exporter/start.sh

注: 第一次使用的时候进行操作

2. 创建配置文件

cp /data/open-c3/prometheus/config/targets/blackbox-exporter-http.example.yml /data/open-c3/prometheus/config/targets/blackbox-exporter-http.yml 

3. 在配置文件中添加自己要监控的url

cat  /data/open-c3/prometheus/config/targets/blackbox-exporter-http.yml
- targets:
  - https://www.baidu.com
  - https://www.github.com


4. reload prometheus

/data/open-c3/prometheus/bin/reload.sh

```

## 说明

```
当前操作步骤过于繁琐，后续可能会把这个服务做成默认开启。

要监控的url临时先通过修改文件的方式进行配置，后续会在前端上添加页面管理要监控的url。

```

## 其他

```
如果是tcp监控，请按照上面http的方式编辑如下文件

cat /data/open-c3/prometheus/config/targets/blackbox-exporter-tcp.yml 
- targets:
  - 172.10.10.1:2181
  - 172.10.10.2:2181

```
