#!/bin/bash

if [ ! -f /data/open-c3/alertmanager/config/alertmanager.yml ];then
    cp /data/open-c3/alertmanager/config/alertmanager.example.yml /data/open-c3/alertmanager/config/alertmanager.yml
fi

X=$(docker inspect  openc3-alertmanager 2>&1|grep Created|wc -l)

if [ "X1" == "X$X"  ]; then
    docker start openc3-alertmanager
else
    docker run --name openc3-alertmanager -d -p 9093:9093 -v /data/open-c3/alertmanager/config:/etc/alertmanager prom/alertmanager:latest
fi

