#!/bin/bash
set -ex

cd /data/open-c3/Installer/C3/pkg/install-cache || exit

if [ ! -d install-cache ];then
    git clone https://github.com/open-c3/open-c3-install-cache install-cache
fi
bash -c "cd install-cache && git pull";
tar -zcf install-cache.tar.gz install-cache --exclude .git

mkdir -p _tempdata/open-c3/Connector/pkg
mv install-cache.tar.gz _tempdata/open-c3/Connector/pkg/
mv _tempdata tempdata
