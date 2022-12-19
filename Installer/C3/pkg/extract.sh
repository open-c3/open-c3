#!/bin/bash
set -e

VERSION=2212194
if [ "X$1" != "X" ];then
    VERSION=$1
fi
echo VERSION:$VERSION

docker run --rm -v /data/open-c3:/data/open-c3 openc3/pkg:$VERSION

bash -c "cd /data/open-c3/Connector/pkg && tar -zxvf install-cache.tar.gz";
bash -c "cd /data/open-c3/Connector/pkg && tar -zxvf dev-cache.tar.gz";
bash -c "cd /data/open-c3/Connector/pkg && tar -zxvf book.tar.gz";

# install-cache
if [ -d "/data/open-c3/Installer/install-cache" ] && [ ! -L "/data/open-c3/Installer/install-cache" ] ; then
    rm -rf /data/open-c3/Installer/install-cache
fi
ln -fsn /data/open-c3/Connector/pkg/install-cache /data/open-c3/Installer/install-cache

# dev-cache
if [ -d "/data/open-c3/Installer/dev-cache" ] && [ ! -L "/data/open-c3/Installer/dev-cache" ] ; then
    rm -rf /data/open-c3/Installer/dev-cache
fi
ln -fsn /data/open-c3/Connector/pkg/dev-cache /data/open-c3/Installer/dev-cache
