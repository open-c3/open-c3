#!/bin/bash

mkdir -p /data/open-c3-data/glusterfs/maintain
cd /data/open-c3-data/glusterfs/maintain || exit

mkdir -p /data/open-c3-data/private /data/open-c3-data/grafana-data

DPATH=/data/Software/mydan
if [ "X$OPEN_C3_NAME" == "X" ];then
    DPATH=/data/open-c3
fi

cp data/current                      $DPATH/Connector/config.ini/current
rsync -av data/account/              $DPATH/AGENT/device/conf/account/
rsync -av data/prometheus/config/    $DPATH/prometheus/config/

cp data/sysctl.conf                  /data/open-c3-data/

rsync -av data/auth/                 /data/open-c3-data/auth/
rsync -av data/private/              /data/open-c3-data/private/

cp data/grafana-data/grafana.db      /data/open-c3-data/grafana-data/grafana.db.temp
mv /data/open-c3-data/grafana-data/grafana.db.temp /data/open-c3-data/grafana-data/grafana.db
