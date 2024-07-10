# 监控/监控告警转发

```
有些监控，是直接产生于其他平台，比如华为云、AWS等。
为了方便的统一查看所有的告警和统一告警出口，Open-C3提供了回调地址。允许其他监控告警消息回调到Open-C3上。

```

## 配置回调地址

```
在第三方平台上添加Open-C3的回调地址
http://open-c3xxx.com/api/ci/exmesg/[type]?group=[report_group]

其中[type]是消息的类型，消息处理的时候会根据这个类型进行处理，如果没有定义，就会用默认的处理方式。
[report_group]对应C3里面的告警组，如果找不到对应的组，会默认使用名字为report的组。

[例] http://open-c3xxx.com/api/ci/exmesg/huawei_rds?group=huawei_report

[注]当前支持的type: nexus 、default
```
