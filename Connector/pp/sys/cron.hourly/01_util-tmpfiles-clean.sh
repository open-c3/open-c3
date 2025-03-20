#!/bin/bash

find /tmp -type f -mtime +7 -exec rm -f {} \;
find /tmp -name "c3-device-control-tmp-*.yml" -type f -mtime +1 -exec rm -f {} \;

find /data/open-c3-data/monitor-exalarm -type f -mtime +7 -exec rm -f {} \;

find /data/open-c3-data/logs/CI/webhooks_logs -type f -mtime +7 -exec rm -f {} \;
find /data/open-c3-data/logs/CI/webhooks_data -type f -mtime +7 -exec rm -f {} \;

find /data/open-c3-data/monitor-exmesg/uuid -type f -mtime +3 -exec rm -f {} \;
find /data/open-c3-data/monitor-exmesg/uuid -type f -mtime +1 -name "*exmesg.del" -exec rm -f {} \;
find /data/open-c3-data/monitor-exmesg/succ -type f -mtime +30 -exec rm -f {} \;
find /data/open-c3-data/monitor-exmesg/fail -type f -mtime +30 -exec rm -f {} \;
find /data/open-c3-data/monitor-exmesg/error -type f -mtime +30 -exec rm -f {} \;
find /data/open-c3-data/monitor-exmesg/queue -type f -mtime +30 -exec rm -f {} \;

find /data/Software/mydan/AGENT/device/conf/accountdb.temp -type f -mmin +30 -exec rm -f {} \;
find /data/Software/mydan/AGENT/device/conf/accountdb.temp -type d -mmin +40 -exec rmdir {} \;
