#!/bin/bash

mkdir -p /data/open-c3-blackbox-exporter
cd /data/open-c3-blackbox-exporter

mkdir config

wget https://raw.githubusercontent.com/open-c3/open-c3/v2.6.1/AGENT/monitor/blackbox-exporter/config/blackbox.yml -O config/blackbox.yml

docker run -d --restart=always \
  --name openc3-blackbox_exporter \
  -p 9115:9115 \
  -v /data/open-c3-blackbox-exporter/config:/config \
  prom/blackbox-exporter:master --config.file=/config/blackbox.yml
