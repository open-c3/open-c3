#!/bin/bash
set -x

ttpid=$(ps -ef|grep connector.server.trouble-ticketing|grep -v grep|awk '{print $3}')

if [ "X$ttpid" != "X" ];then
    ps -ef|grep "$ttpid"|grep connector_supervisor|awk '{print $2}'|xargs -i{} kill {}
fi

ps -ef|grep trouble-ticketing|grep -v grep|grep -v tdev.sh|awk '{print $2}'|xargs -i{} kill {}

cd /data/Software/mydan/Connector/tt/trouble-ticketing && ./trouble-ticketing
