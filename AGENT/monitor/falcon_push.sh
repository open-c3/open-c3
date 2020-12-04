#!/bin/bash

basedir=`cd $(dirname $0); pwd -P`
cd $basedir

endpoint=$(hostname)
ts=`date +%s`;

function push()
{
    curl -X POST -d "[{\"metric\": \"$1\", \"endpoint\": \"$endpoint\", \"timestamp\": $ts,\"step\": 60,\"value\": $2,\"counterType\": \"GAUGE\",\"tags\": \"project=whiteking,module=agent\"}]" http://127.0.0.1:1988/v1/push
}

if [ ! -f "/usr/bin/tsocks" ];then
   tsocks=0
else
   tsocks=$(readlink /etc/tsocks.conf |cut -c 17)
fi

push tsocks.status $tsocks

oo=$(date +"%d %H:%M" -d "1 minute ago");
xx=$(date +"%d %I:%M" -d "1 minute ago");
push api.qps $(tail -n 10000 /var/log/messages|grep /data/Software/mydan/AGENT/lib/api.pm |grep -E "$oo|$xx"|wc -l )
