#!/bin/bash
set -e

cd /data/open-c3/AGENT/c3demoslave

if [ ! -f .env ]; then
    echo onfind .env
    exit 1
fi

/data/open-c3-data/cloudmon/docker-compose  build
/data/open-c3-data/cloudmon/docker-compose  up -d --scale openc3-demo-slave=10
docker exec openc3-server /data/Software/mydan/AGENT/c3demoslave/update.sh
