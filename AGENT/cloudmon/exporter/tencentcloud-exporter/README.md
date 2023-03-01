# 监控采集器/云监控/腾讯云

## github

https://github.com/tencentyun/tencentcloud-exporter

## 配置例子
```
---
credential:
  access_key: "ak"
  secret_key: "sk"
  region: "ap-beijing"
products:
  - namespace: QCE/CMONGO
    only_include_metrics: [ClusterDiskusage,Connper]    
    all_instances: true
    extra_labels: [InstanceName,Zone]
  - namespace: QCE/CDB
    only_include_metrics: [CpuUseRate,MemoryUseRate,VolumeRate,Capacity]
    all_instances: true
    extra_labels: [InstanceName,Zone]
  - namespace: QCE/REDIS_MEM
    only_include_metrics: [CpuMaxUtil,MemMaxUtil] 
    all_instances: true
    extra_labels: [InstanceName,Zone]
```
## 获取metrics列表

github 地址的文档里面有, https://github.com/tencentyun/tencentcloud-exporter

## CMDB联动

本exporter和tencentcloud-cache-exporter功能一致，tencentcloud-cache-exporter是被c3特殊处理优化过的，自动联动的部分默认使用tencentcloud-cache-exporter。

所以要想做联动，请到tencentcloud-cache-exporter下查看。
