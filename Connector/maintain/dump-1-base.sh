#!/bin/bash

V=$1
DIST=/data/open-c3-data/glusterfs/maintain
if [ "X$V" != "X" ];then
    DIST="$DIST-$V"
fi
mkdir -p $DIST
cd $DIST || exit

mkdir -p data/auth
cp /data/open-c3/Connector/config.ini/current data/
cp /data/open-c3-data/sysctl.conf             data/

cp -r /data/open-c3-data/auth/* data/auth/

mkdir -p data/private
rsync -av /data/open-c3-data/private/ data/private/
