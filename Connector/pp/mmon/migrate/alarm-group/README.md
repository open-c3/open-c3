# 监控迁移/迁移告警组

```
# debug.csv 文件中有三列数据，第一列是组名，第二例是用户列表（多个用户用英文的逗号分隔），第三列是组的备注信息
# 执行下面的命令导入组

cat debug.csv |sed 1d|sed 's/\t/;/g' | c3mc-mon-alarm-group-load --user 'openc3-migrate@sys'

# 注: 上述命令会去掉第一行的表头
```
