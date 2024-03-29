#!/bin/bash

set -e

URL=$1

if [ "X$URL" == "X" ]; then
    echo $0 http://x.x.x.x/cmdb-demo.xxx.tar.gz
    exit 1
fi
wget $URL -O /data/open-c3-data/device/cmdb-demo.tar.gz
tar -zxf /data/open-c3-data/device/cmdb-demo.tar.gz -C /data/open-c3-data/device

docker exec openc3-server /usr/bin/c3mc-device-bind-info-cache set
docker exec openc3-server /usr/bin/c3mc-device-cat-all-cache   set
