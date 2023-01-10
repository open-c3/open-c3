#!/bin/bash
set -ex

cd /data/open-c3/Installer/C3/pkg/dev-cache || exit

if [ ! -d dev-cache ];then
    git clone https://github.com/open-c3/open-c3-dev-cache dev-cache
fi
bash -c "cd dev-cache && git pull";
tar -zcf dev-cache.tar.gz dev-cache --exclude .git

mkdir -p _tempdata/open-c3/Connector/pkg
mv dev-cache.tar.gz _tempdata/open-c3/Connector/pkg/
mv _tempdata tempdata
