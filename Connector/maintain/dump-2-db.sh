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

docker exec -i openc3-mysql mysqldump -h127.0.0.1 -uroot -popenc3123456^! --databases jobs jobx ci agent connector > data/mysql/openc3.${version}.sql
