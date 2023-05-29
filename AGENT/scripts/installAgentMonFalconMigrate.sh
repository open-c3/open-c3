#!/bin/bash

set -e 

MYDanPATH=/opt/mydan

if [ ! -d "$MYDanPATH/dan" ]; then
    echo "nofind mydan path: $MYDanPATH/dan"
    exit
fi

if [ ! -f "$MYDanPATH/dan/bootstrap/exec/mydan.node_exporter.65110" ]; then
    echo "nofind mydan 65110: install mon agent first"
    exit
fi

if [ ! -f "/data/Software/open-falcon/agent/control" ]; then
    echo "nofind falcon control"
    exit
fi

if [ ! -f "/data/Software/open-falcon/agent/cfg.json" ]; then
    echo "nofind falcon cfg.json"
    exit
fi

cd "$MYDanPATH/dan" || exit 1

/opt/mydan/dan/agent.mon/bin/falcon_migrate_ecs_tag

cp /opt/mydan/dan/agent.mon/exec.config/mydan.falcon_migrate.1988 /opt/mydan/dan/bootstrap/exec/
chmod +x /opt/mydan/dan/bootstrap/exec/mydan.falcon_migrate.1988

if [ -f /data/Software/open-falcon/agent/cfg.json.c3.bak ];then
    cp /data/Software/open-falcon/agent/cfg.json /data/Software/open-falcon/agent/cfg.json.c3.bak
fi
sed -i 's/"listen": ":1988"/"listen": ":1987"/' /data/Software/open-falcon/agent/cfg.json

lsof -i:1988|tail -n 1|awk '{print $2}'|xargs -i{} kill {}

/data/Software/open-falcon/agent/control restart

ps -ef|grep mydan.falcon_migrate.1988|grep -v grep|awk '{print $2}'|xargs -i{} kill {}

echo "INSTALL OPEN-C3 MONITOR AGENT falcon_migrate: SUCCESS!!!"
