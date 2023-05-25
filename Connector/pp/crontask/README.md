# 系统CronTask

```
由文件/data/open-c3-data/bpm/crontask.txt控制
文件格式:
   动作;执行时间;操作对象;操作对象的owner暂时没用到);作用开始时间;作用结束时间
如

foo;22;10.10.10.10;open-c3;0;99999999999999
bar;* * * * *;10.10.10.2;open-c2;0;99999999999999

其中动作字段会在/data/open-c3/Connector/pp/crontask/action/目录下有对应的操作脚本。
如foo动作当前有两个操作对象node1和node2，会调用 /data/open-c3/Connector/pp/crontask/action/foo 'node1,node2'

默认短信通知用户：crontask-bot
```
