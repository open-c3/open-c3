#!/bin/bash

docker run -d \
  -v /bin/docker:/bin/docker \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /data/open-c3-data/redis-exporter-v3:/data/open-c3-data/redis-exporter-v3 \
  -p 65114:65114 \
  --network c3_JobNet \
  --name openc3-redis-query \
  -e C3_RedisQuery_Container=1 \
  openc3/redis-query:e2209281
