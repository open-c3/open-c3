#!/bin/bash

curl -L $OPEN_C3_ADDR/api/scripts/installQueryInit.sh | bash

IMAGE=openc3/mysql-query:m2211101
VPATH=mysqld-exporter-v3
NAME=openc3-mysql-query

C=$(docker ps|grep "$IMAGE"|grep -v grep|wc -l)
if [ "X$C" != "X0" ];then
    echo "Already installed $IMAGE, skip!"
    exit;
fi

docker pull $IMAGE

docker stop $NAME
docker rm   $NAME

docker run -d \
  -v /bin/docker:/bin/docker \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /data/open-c3-data/$VPATH:/data/open-c3-data/$VPATH \
  -p 65113:65113 \
  --network c3_JobNet \
  --name $NAME \
  -e C3_MysqlQuery_Container=1 \
  $IMAGE
