#!/bin/bash

Name=${1:-default}

Curr=$(< /var/prometheus-reload-go-$Name.txt)
Mark=$(< /var/prometheus-reload-mark.txt)

if [ "X$Curr" == "X$Mark" ];then
    /data/Software/mydan/prometheus/bin/reload-go2.sh $Name
    exit
fi

echo "$Mark" > /var/prometheus-reload-go-$Name.txt

echo $(date "+%F %H:%M:%S") "$Mark $Name" >> /var/prometheus-reload-mark.log

curl -XPOST http://openc3-prometheus:9090/-/reload 2>/dev/null
