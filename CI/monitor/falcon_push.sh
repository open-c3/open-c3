#!/bin/bash
basedir=`cd $(dirname $0); pwd -P`
cd $basedir

endpoint=$(hostname)
ts=`date +%s`;

function push()
{
    curl -X POST -d "[{\"metric\": \"$1\", \"endpoint\": \"$endpoint\", \"timestamp\": $ts,\"step\": 60,\"value\": $2,\"counterType\": \"GAUGE\",\"tags\": \"project=whiteking,module=ci\"}]" http://127.0.0.1:1988/v1/push
}

push project.count $(../debugtools/mysql  -s "select count(*) from project where slave=\"$endpoint\" and status=1"|tail -n 1 )
push tags.count $(../debugtools/mysql  -s "select count(*) from version where slave=\"$endpoint\""|tail -n 1 )
push tags.success $(../debugtools/mysql  -s "select count(*) from version where status=\"success\" and slave=\"$endpoint\""|tail -n 1 )
push tags.fail $(../debugtools/mysql  -s "select count(*) from version where status=\"fail\" and slave=\"$endpoint\""|tail -n 1 )

oo=$(date +"%d %H:%M" -d "1 minute ago");
xx=$(date +"%d %I:%M" -d "1 minute ago");
push api.qps $(tail -n 10000 /var/log/messages|grep /data/Software/mydan/CI/lib/api.pm |grep -E "$oo|$xx"|wc -l )
