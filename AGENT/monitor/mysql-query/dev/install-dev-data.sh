#!/bin/bash

DIST=monitor-mysql-dev
if [ "X$1" == "Xdemo" ]; then
    DIST=idc-mysql

    mkdir -p /data/open-c3-data/device/curr/auth/mysql.auth
    date > /data/open-c3-data/device/curr/auth/mysql.auth/open-c3
fi
mkdir -p /data/open-c3-data/device/curr/database/$DIST/
rsync  -av /data/open-c3/AGENT/monitor/mysql-query/dev/monitor-mysql-dev/ /data/open-c3-data/device/curr/database/$DIST/
