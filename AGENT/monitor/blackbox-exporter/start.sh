#!/bin/bash

docker run -d --restart=always \
  --name openc3-blackbox_exporter \
  --network c3_JobNet \
  -v /data/open-c3/AGENT/monitor/blackbox-exporter/config:/config \
  prom/blackbox-exporter:master --config.file=/config/blackbox.yml
