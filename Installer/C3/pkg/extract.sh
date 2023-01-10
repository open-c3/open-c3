#!/bin/bash
set -e

cd /data/open-c3/Installer/C3/pkg || exit 1

cat module|xargs -i{} bash -c "./extract-module.sh {} || exit 255"

tar -zxvf install-cache.tar.gz;
tar -zxvf dev-cache.tar.gz;
tar -zxvf book.tar.gz;

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
