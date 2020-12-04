#!/bin/bash

basedir=`cd $(dirname $0); pwd -P`
cd $basedir 

endpoint=$(hostname)

ts=`date +%s`;

function push()
{
    curl -X POST -d "[{\"metric\": \"$1\", \"endpoint\": \"$endpoint\", \"timestamp\": $ts,\"step\": 60,\"value\": $2,\"counterType\": \"GAUGE\",\"tags\": \"project=whiteking,module=jobx\"}]" http://127.0.0.1:1988/v1/push
}

push task.count $(../debugtools/mysql  -s "select count(*) from task where slave=\"$endpoint\""|tail -n 1 )

oo=$(date +"%d %H:%M" -d "1 minute ago");
xx=$(date +"%d %I:%M" -d "1 minute ago");
push api.qps $(tail -n 10000 /var/log/messages|grep /data/Software/mydan/JOBX/lib/api.pm |grep -E "$oo|$xx"|wc -l )
