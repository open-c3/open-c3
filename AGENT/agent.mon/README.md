更新

```
版本2:
    解决进程采集太耗CPU的问题。

版本3:
    进程监控匹配方式改成“包含”字符。
    修改了进程启动时间的获取方式。
    进程监控指标node_process_time改成node_process_etime。
```

node_collector_error 错误码

```
-1: 启动中
0: 正常
1: 错误
2: 超时
```
