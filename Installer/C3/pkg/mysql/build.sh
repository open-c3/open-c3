#!/bin/bash
set -ex

VERSION=$1
if [ "X$VERSION" == "X" ];then
    VERSION=$(date +%y%m%d)
fi
echo VERSION:$VERSION

cd /data/open-c3/Installer/C3/pkg/mysql || exit

docker build . -t openc3/pkg-mysql:$VERSION --no-cache

docker run -v /data/open-c3/Installer/C3/pkg/mysql:/tempdata openc3/pkg-mysql:$VERSION

chmod +x mysql
mkdir -p _tempdata/open-c3/Connector/pkg
mv mysql _tempdata/open-c3/Connector/pkg/
mv _tempdata tempdata
