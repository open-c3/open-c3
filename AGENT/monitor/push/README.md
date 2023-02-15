# 监控/自定义push指标

```
通过本地脚本push的方式添加监控指标
把采集脚本添加到crontab中每分钟执行一次
```
## 脚本介绍

### vm_dns_check

用途：监控本地主机dns解析是否正常，可以同时监控多个

例：
```
    ./vm_dns_check.sh www.baidu.com      # 不写名称默认名称为default
    ./vm_dns_check.sh www.google.com abc
```

到监控系统中使用监控指标vm_dns_check配置告警。
