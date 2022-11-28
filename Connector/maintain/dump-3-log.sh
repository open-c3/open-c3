#!/bin/bash

V=$1
DIST=/data/open-c3-data/glusterfs/maintain
if [ "X$V" != "X" ];then
    DIST="$DIST-$V"
fi
mkdir -p $DIST
cd $DIST || exit


mkdir -p data/logs
rsync -av /data/open-c3-data/logs/ data/logs/ --exclude CI/build_temp_uuid --exclude CI/git_cache
