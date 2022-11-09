#!/bin/bash

DIST=monitor-redis-dev

if [ "X$1" == "Xdemo" ]; then
    DIST=idc-redis

    mkdir -p /data/open-c3-data/device/curr/auth/redis.auth
    date > /data/open-c3-data/device/curr/auth/redis.auth/open-c3
fi

mkdir -p /data/open-c3-data/device/curr/database/$DIST/
rsync  -av /data/open-c3/AGENT/monitor/redis-query/dev/monitor-redis-dev/ /data/open-c3-data/device/curr/database/$DIST/
