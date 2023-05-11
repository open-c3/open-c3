# 监控/fping

## 操作步骤
```
如果你需要fping监控。可以按照下面步骤进行操作。

1. 开启fping监控容器

/data/open-c3/AGENT/monitor/fping/start.sh

注: 第一次使用的时候进行操作

2. 创建配置文件

cp /data/open-c3/prometheus/config/targets/fping.example.yml /data/open-c3/prometheus/config/targets/fping.yml 

3. 在配置文件中添加自己要监控的url

cat  /data/open-c3/prometheus/config/targets/fping.yml
- targets:
  - 114.114.114.114

4. reload prometheus

/data/open-c3/prometheus/bin/reload.sh

```
## 说明

```
当前操作步骤过于繁琐，后续可能会把这个服务做成默认开启。

要监控的ping临时先通过修改文件的方式进行配置，后续会在前端上添加页面管理要监控的地址。

```
