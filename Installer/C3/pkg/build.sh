#!/bin/bash
set -ex

VERSION=$1
if [ "X$VERSION" == "X" ];then
    VERSION=$(date +%y%m%d)
fi
echo VERSION:$VERSION

cd /data/open-c3/Installer/C3/pkg || exit

rm -rf tempdata
mkdir  tempdata

# trouble-ticketing
bash -c "cd /data/open-c3/Connector/tt/trouble-ticketing && ./build.sh"
mkdir -p tempdata/open-c3/pkg
cp /data/open-c3/Connector/tt/trouble-ticketing/trouble-ticketing tempdata/open-c3/pkg/
chmod +x tempdata/open-c3/pkg/trouble-ticketing

#jumpserver
bash -c "cd /data/open-c3/Connector/bl/sync/jumpserver && ./build.sh"
mkdir -p tempdata/open-c3/Connector/bl/sync/jumpserver
cp /data/open-c3/Connector/bl/sync/jumpserver/jumpserver tempdata/open-c3/Connector/bl/sync/jumpserver/
chmod +x tempdata/open-c3/Connector/bl/sync/jumpserver/jumpserver

# baseinfo
git log                > tempdata/git.log
git branch | grep '^*' > tempdata/git.branch

docker build . -t openc3/pkg:$VERSION --no-cache
