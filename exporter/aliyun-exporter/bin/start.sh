#!/bin/bash

Config=/data/open-c3/exporter/aliyun-exporter/conf/aliyun-exporter.yml
test -f $Config || exit 1

docker run -d \
  -p 9525:9525 \
  -v $Config:/aliyun-exporter.yml \
  --name openc3-aliyun-exporter \
  aylei/aliyun-exporter:0.3.1 -c /aliyun-exporter.yml
