#!/bin/bash

curl -L $OPEN_C3_ADDR/api/scripts/installQueryInit.sh | bash

IMAGE=openc3/redis-query:e2211121
VPATH=redis-exporter-v3
NAME=openc3-redis-query

docker pull $IMAGE

docker stop $NAME 2>/dev/null
docker rm   $NAME 2>/dev/null

docker run -d \
  -v /bin/docker:/bin/docker \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /data/open-c3-data/$VPATH:/data/open-c3-data/$VPATH \
  -p 65114:65114 \
  --network c3_JobNet \
  --name $NAME \
  -e C3_RedisQuery_Container=1 \
  $IMAGE
