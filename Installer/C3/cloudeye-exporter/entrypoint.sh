#!/bin/bash
set -e

metric=$(cat /clouds.yml |grep ^metric:|awk '{print $2}')

if [ "X$metric" != "X" ];then
    cp /metric/$metric.yml /metric.yml
fi

exec /cloudeye-exporter
