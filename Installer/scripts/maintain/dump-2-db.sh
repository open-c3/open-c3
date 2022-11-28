#!/bin/bash

version=$(date +%y%m%d.%H%M%S)

V=$1
DIST=/data/open-c3-data/glusterfs/maintain
if [ "X$V" != "X" ];then
    DIST="$DIST-$V"
    version=$V
fi
mkdir -p $DIST
cd $DIST || exit


mkdir -p  data/mysql

/data/open-c3/Installer/scripts/databasectrl.sh  backup $version
cp /data/open-c3-data/backup/mysql/openc3.${version}.sql data/mysql/
