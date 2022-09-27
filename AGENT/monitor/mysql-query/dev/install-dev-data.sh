#!/bin/bash

mkdir -p /data/open-c3-data/device/curr/database/monitor-mysql-dev/
rsync  -av /data/open-c3/AGENT/monitor/mysql-query/dev/monitor-mysql-dev/ /data/open-c3-data/device/curr/database/monitor-mysql-dev/
