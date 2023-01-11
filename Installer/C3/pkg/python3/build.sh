#!/bin/bash
set -ex

VERSION=$1
if [ "X$VERSION" == "X" ];then
    VERSION=$(date +%y%m%d)
fi
echo VERSION:$VERSION

cd /data/open-c3/Installer/C3/pkg/python3 || exit

docker build . -t openc3/pkg-python3:$VERSION --no-cache

docker run -v /data/open-c3/Installer/C3/pkg/python3:/tempdata openc3/pkg-python3:$VERSION

mkdir -p _tempdata/open-c3/Connector/pkg
mv python3.tar.gz _tempdata/open-c3/Connector/pkg/python3.tar.gz
mv _tempdata tempdata
