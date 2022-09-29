#!/bin/bash

docker run -d \
  -v /bin/docker:/bin/docker \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /data/open-c3-data/mongodb-exporter-v3:/data/open-c3-data/mongodb-exporter-v3 \
  -p 65115:65115 \
  --network c3_JobNet \
  --name openc3-mongodb-query \
  -e C3_MongodbQuery_Container=1 \
  openc3/mongodb-query:o2209291
