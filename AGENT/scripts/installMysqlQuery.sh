#!/bin/bash

curl -L $OPEN_C3_ADDR/api/scripts/installQueryInit.sh | bash

IMAGE=openc3/mysql-query:m2506171
VPATH=mysqld-exporter-v3
NAME=openc3-mysql-query

C=$(docker ps|grep "$IMAGE"|grep -v grep|wc -l)
if [ "X$C" != "X0" ];then
    echo "Already installed $IMAGE, skip!"
    exit;
fi

docker pull $IMAGE

docker stop $NAME 2>/dev/null
docker rm   $NAME 2>/dev/null

docker run -d \
  --restart unless-stopped \
  -v /bin/docker:/bin/docker_v1.0.0 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /data/open-c3-data/$VPATH:/data/open-c3-data/$VPATH \
  -p 65113:65113 \
  --network c3_JobNet \
  --name $NAME \
  -e C3_MysqlQuery_Container=1 \
  $IMAGE
