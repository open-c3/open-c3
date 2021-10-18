#!/bin/bash

X=$(docker inspect openc3-grafana 2>&1|grep Created|wc -l)

if [ "X1" == "X$X"  ]; then
    docker start openc3-grafana
else
    mkdir -p /data/grafana-data
    docker run --user root -d -p 3000:3000 --name=openc3-grafana -v /data/grafana-data:/var/lib/grafana grafana/grafana:7.3.6
fi
