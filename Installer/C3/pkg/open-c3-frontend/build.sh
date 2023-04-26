#!/bin/bash
set -ex

VERSION=$1
if [ "X$VERSION" == "X" ];then
    VERSION=$(date +%y%m%d)
fi
echo VERSION:$VERSION

cd /data/open-c3/Installer/C3/pkg/open-c3-frontend || exit

mkdir -p _tempdata/open-c3/c3-front
cp -r /data/open-c3-frontend/dist _tempdata/open-c3/c3-front/dist_v2
mv _tempdata tempdata
