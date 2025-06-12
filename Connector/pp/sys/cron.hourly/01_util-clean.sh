#!/bin/bash
#docker images|grep '<none>'|awk '{print $3}'|xargs -i{} docker rmi {}
#docker ps -a|grep openc3ci|grep -v 'Exited (0)'|awk '{print $1}'|xargs -i{} docker rm {}
#docker system prune

# 这里可以优化一下，同步的时候不要同步它，免得删除一次。
# 但是历史遗留，需要先把历史的都删除了
find /data/Software/mydan/AGENT/device/conf/account.temp  -mtime +1 -exec rm -rf {} \;
rm -rf /data/open-c3-data/device/curr/conf/account.temp
rm -rf /data/open-c3-data/device/timemachine/*/conf/account.temp
