#!/bin/bash

mkdir -p /data/open-c3-data/device/curr/database/monitor-redis-dev/
rsync  -av /data/open-c3/AGENT/monitor/redis-query/dev/monitor-redis-dev/ /data/open-c3-data/device/curr/database/monitor-redis-dev/
