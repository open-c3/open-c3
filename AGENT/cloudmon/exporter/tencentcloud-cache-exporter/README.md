# 监控采集器/云监控/腾讯云cache

是tencentcloud-exporter的cache版，tencentcloud-exporter采集数据不稳定，有丢数据的情况。

通过c3的接口进行缓存，如果拿到的数据小于之前正常数据的75%则使用旧的数据返回。

旧的数据最多使用3分钟，如果3分钟后还是不正常的，则返回不正常的数据。

## CMDB联动

执行下面命令，把cmdb中的云账号自动同步到云监控中

```
docker exec openc3-server /data/Software/mydan/AGENT/cloudmon/exporter/tencentcloud-cache-exporter/config-make-from-cmdb 
```

注:  这里暂时不做自动处理，后续看情况可能会让程序自动做联动
