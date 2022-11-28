#!/bin/bash

V=$1
DIST=/data/open-c3-data/glusterfs/maintain
if [ "X$V" != "X" ];then
    DIST="$DIST-$V"
fi
mkdir -p $DIST
cd $DIST || exit

mkdir -p data/auth data/account data/private data/grafana-data data/prometheus/config

DPATH=/data/Software/mydan
if [ "X$OPEN_C3_NAME" == "X" ];then
    DPATH=/data/open-c3
fi

cp        $DPATH/Connector/config.ini/current   data/
rsync -av $DPATH/AGENT/device/conf/account/     data/account/
rsync -av $DPATH/prometheus/config/             data/prometheus/config/

cp /data/open-c3-data/sysctl.conf               data/

rsync -av /data/open-c3-data/auth/              data/auth/
rsync -av /data/open-c3-data/private/           data/private/

cp /data/open-c3-data/grafana-data/grafana.db   data/grafana-data/
