#!/bin/bash

mkdir -p /data/open-c3-data/device/curr/database/monitor-mongodb-dev/
rsync  -av /data/open-c3/AGENT/monitor/mongodb-query/dev/monitor-mongodb-dev/ /data/open-c3-data/device/curr/database/monitor-mongodb-dev/
