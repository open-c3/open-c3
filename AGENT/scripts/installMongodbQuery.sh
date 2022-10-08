#!/bin/bash

curl -L $OPEN_C3_ADDR/api/scripts/installQueryInit.sh | bash

IMAGE=openc3/mongodb-query:o2209291
VPATH=mongodb-exporter-v3
NAME=openc3-mongodb-query

docker pull $IMAGE

docker stop $NAME
docker rm   $NAME

docker run -d \
  -v /bin/docker:/bin/docker \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /data/open-c3-data/$VPATH:/data/open-c3-data/$VPATH \
  -p 65115:65115 \
  --network c3_JobNet \
  --name $NAME \
  -e C3_MongodbQuery_Container=1 \
  $IMAGE
