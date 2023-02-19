# 自动测试/pr自动测试机器人

## 安装
```
1. 找一台机器安装单机版C3，切换到指定分支v2.6.0
2. 把/data/open-c3/tools/pr 拷贝到 /data/open-c3-pr
3. 添加机器人github账号的个人token到/etc/c3bot.token
4. 添加定时任务每5分钟执行一次检查
    */3 * * * * flock -n /var/c3bot-pr.lock /data/open-c3-pr/run /data/open-c3-pr > /tmp/c3bot-pr.log 2> /tmp/c3bot-pr.err
```

## 其它
```
需要测试的命令写到/data/open-c3/tools/pr/test中。

注: 如test文件有更新，需要手动更新到/data/open-c3-pr 下。
```
