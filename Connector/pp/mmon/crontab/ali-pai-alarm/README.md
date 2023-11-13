# 监控/ali-pai 任务监控

```
在文件aksk.sh中写入aksk（可以参考aksk.sh.example文件的写法）。

在/data/open-c3/Connector/openc3.task.crontab中添加下面两条任务。
*/5 * * * * root flock -n /tmp/ali-pai-alarm.lock  /data/Software/mydan/Connector/pp/mmon/crontab/ali-pai-alarm/run.sh > /tmp/ali-pai-alarm.log 2>&1
0 * * * * root   flock -n /tmp/ali-pai-notofy.lock  /data/Software/mydan/Connector/pp/mmon/crontab/ali-pai-alarm/runnotify.sh > /tmp/ali-pai-notify.log 2>&1

```
