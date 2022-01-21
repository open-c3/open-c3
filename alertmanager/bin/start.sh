#!/bin/bash

#该脚本只适用于集群版，单机版的已经通过docker-compose管理，
#在Installer/scripts/single.sh的start脚本中已做了以下初始化的部分工作

if [ ! -f /data/open-c3/alertmanager/config/alertmanager.yml ];then
    cp /data/open-c3/alertmanager/config/alertmanager.example.yml /data/open-c3/alertmanager/config/alertmanager.yml
fi

X=$(docker inspect  openc3-alertmanager 2>&1|grep Created|wc -l)

if [ "X1" == "X$X"  ]; then
    docker start openc3-alertmanager
else
    docker run --name openc3-alertmanager -d -p 9093:9093 -v /data/open-c3/alertmanager/config:/etc/alertmanager prom/alertmanager:latest
fi

