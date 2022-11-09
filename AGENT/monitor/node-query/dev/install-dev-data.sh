#!/bin/bash

DIST=monitor-node-dev
if [ "X$1" == "Xdemo" ]; then
    DIST=idc-node
fi
mkdir -p /data/open-c3-data/device/curr/compute/$DIST/
rsync  -av /data/open-c3/AGENT/monitor/node-query/dev/monitor-node-dev/ /data/open-c3-data/device/curr/compute/$DIST/
