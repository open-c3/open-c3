#!/bin/bash

docker run -d \
  -v /bin/docker:/bin/docker \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /data/open-c3-data/mysqld-exporter-v3:/data/open-c3-data/mysqld-exporter-v3 \
  -p 65113:65113 \
  --network c3_JobNet \
  --name openc3-mysql-query \
  -e C3_MysqlQuery_Container=1 \
   openc3/mysql-query:m2209251
