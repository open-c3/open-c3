# 监控迁移/告警订阅迁移

```
# debug.csv 中和策略导入使用的是同一个文件，使用了文件中的treeid和uic字段。
# 导入之前需要把告警组和告警人的地址簿导入。因为原始的uic字段是不区分人和组的。
# 导入的过程中会在c3的数据库查找来定义对应的uic是人还是组
# 执行下面的命令导入数据

cat debug.csv |./make-data | c3mc-base-monitorsubscribe-load --user 'openc3-migrate@sys'
```
