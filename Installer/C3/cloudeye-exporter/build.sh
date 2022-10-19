#!/bin/bash
set -ex

VERSION=$1
if [ "X$VERSION" == "X" ];then
    VERSION=$(cat temp/.version)-$(date +%Y%m%d)
fi
echo VERSION:$VERSION
docker build . -t openc3/cloudeye-exporter:$VERSION --no-cache

docker ps|grep 0.0.0.0:8087|awk '{print $1}'| xargs -i{} docker kill {}

docker run -it -p 8087:8087 \
  -v /data/open-c3/AGENT/cloudmon/exporter/cloudeye-exporter/metric:/metric \
  -v /data/open-c3/Installer/C3/cloudeye-exporter/clouds.yml:/clouds.yml \
  openc3/cloudeye-exporter:$VERSION
