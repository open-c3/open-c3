# 监控迁移/迁移告警接收人信息

```
# debug.csv 文件中有四列数据，第一列是用户名、第二例是邮箱地址、
# 第三列接收短信的手机号、第四列是接收电话的手机号（可以为空，为空时和短信手机号一致）。
# 执行下面的命令导入数据

cat debug.csv |sed 1d|sed 's/\t/;/g' | c3mc-base-useraddr-load --user 'openc3-migrate@sys'

# 注: 上述命令会去掉第一行的表头
```
