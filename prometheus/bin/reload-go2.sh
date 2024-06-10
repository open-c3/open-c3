#!/bin/bash

Name=${1:-default}

Curr=$(< /var/prometheus-reload-go2-$Name.txt)
Mark=$(< /var/prometheus-reload-mark.txt)

[ "X$Curr" == "X$Mark" ] && exit

echo "$Mark" > /var/prometheus-reload-go2-$Name.txt

echo $(date "+%F %H:%M:%S") "$Mark $Name 2" >> /var/prometheus-reload-mark.log

curl -XPOST http://openc3-prometheus:9090/-/reload 2>/dev/null
