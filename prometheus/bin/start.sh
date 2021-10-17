#!/bin/bash

X=$(docker inspect  openc3-prometheus 2>&1|grep Created|wc -l)

mkdir -p /data/prometheus-data
chmod 777 /data/prometheus-data

if [ ! -f /data/open-c3/prometheus/config/prometheus.yml ];then
    cp /data/open-c3/prometheus/config/prometheus.example.yml /data/open-c3/prometheus/config/prometheus.yml
fi

if [ ! -f /data/open-c3/prometheus/config/openc3_node_sd.yml ];then
    cp /data/open-c3/prometheus/config/openc3_node_sd.example.yml /data/open-c3/prometheus/config/openc3_node_sd.yml
fi

if [ "X1" == "X$X"  ]; then
    docker start openc3-prometheus
else
    docker run -d -p 9090:9090 -v /data/prometheus-data:/data/prometheus-data -v /data/open-c3/prometheus:/data/prometheus-root  --name openc3-prometheus prom/prometheus  --config.file  /data/prometheus-root/config/prometheus.yml --storage.tsdb.path=/data/prometheus-data
fi

