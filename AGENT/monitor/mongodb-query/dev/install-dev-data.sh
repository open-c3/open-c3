#!/bin/bash

DIST=monitor-mongodb-dev
if [ "X$1" == "Xdemo" ]; then
    DIST=idc-mongodb

    mkdir -p /data/open-c3-data/device/curr/auth/mongodb.auth
    date > /data/open-c3-data/device/curr/auth/mongodb.auth/open-c3
fi

mkdir -p /data/open-c3-data/device/curr/database/$DIST/
rsync  -av /data/open-c3/AGENT/monitor/mongodb-query/dev/monitor-mongodb-dev/ /data/open-c3-data/device/curr/database/$DIST/
