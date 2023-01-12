#!/bin/bash
set -e

VERSION=$1

if [ "X$VERSION" == "X" ];then
    VERSION=$(date +%y%m%d)
fi
echo VERSION:$VERSION

cd /data/open-c3/Installer/C3/pkg || exit

cat module|grep -v '^#'|xargs -i{} bash -c "./build-module.sh {} $VERSION || exit 255"
