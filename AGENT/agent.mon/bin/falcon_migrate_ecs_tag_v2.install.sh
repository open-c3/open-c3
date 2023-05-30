#!/bin/bash

ECSM=`docker ps|grep amazonaws.com/liveme-falcon-micadvisor-open|wc -l`;

echo ECSM:$ECSM

if [ "X$ECSM" == "X1" ];then
    cp /opt/mydan/dan/agent.mon/bin/falcon_migrate_ecs_tag_v2.crontab  /etc/cron.d/open-c3-falcon_migrate_ecs_tag_v2.crontab
fi
