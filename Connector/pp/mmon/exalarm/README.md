# 监控/监控扩展

```
有些监控，是直接产生于其他平台，比如华为云、AWS等。
为了方便的统一查看所有的告警和统一告警出口，Open-C3提供了回调地址。允许其他监控告警消息回调到Open-C3上。

```

## 华为云

```

在华为云上添加Open-C3的回调地址
[例]http://open-c3xxx.com/api/ci/exalarm/huawei?account=xx&group=yunwei

当告警发生时，可以看到Open-C3的普罗米修斯上会有exalarm监控指标，可以通过这个指标来配置告警。
```
