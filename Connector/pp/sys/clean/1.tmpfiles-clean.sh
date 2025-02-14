#!/bin/bash

find /tmp -type f -mtime +7 -exec rm -f {} \;
find /tmp -name "c3-device-control-tmp-*.yml" -type f -mtime +1 -exec rm -f {} \;

find /data/open-c3-data/monitor-exalarm -type f -mtime +7 -exec rm -f {} \;
