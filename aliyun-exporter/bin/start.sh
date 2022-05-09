#!/bin/bash

test -f /data/open-c3/aliyun-exporter/conf/aliyun-exporter.yml || exit 1

docker run -d \
  -p 9525:9525 \
  -v /data/open-c3/aliyun-exporter/conf/aliyun-exporter.yml:/aliyun-exporter.yml \
  --name openc3-aliyun-exporter \
  aylei/aliyun-exporter:0.3.1 -c /aliyun-exporter.yml
