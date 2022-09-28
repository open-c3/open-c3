#!/bin/bash
set -ex

VERSION=$1
if [ "X$VERSION" == "X" ];then
    VERSION=$(date +%Y%m%d)
fi
echo VERSION:$VERSION
docker build . -t openc3/redis-query:$VERSION --no-cache

docker ps|grep 0.0.0.0:65114|awk '{print $1}'| xargs -i{} docker kill {}

docker run -d -p 65114:65114 \
  -v /bin/docker:/bin/docker \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /data/open-c3-data/redis-exporter-v3:/data/open-c3-data/redis-exporter-v3 \
  -e C3_RedisQuery_Container=1 \
  --network c3_JobNet \
  openc3/redis-query:$VERSION
