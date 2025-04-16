#!/bin/bash
set -e

cd /data/open-c3/AGENT/c3demoslave

if [ ! -f .env ]; then
    echo onfind .env
    exit 1
fi

DOCKER_COMPOSE_VERSION=1.29.2 /data/open-c3/Installer/docker-compose build
DOCKER_COMPOSE_VERSION=1.29.2 /data/open-c3/Installer/docker-compose up -d --scale openc3-demo-slave=10
docker exec openc3-server /data/Software/mydan/AGENT/c3demoslave/update.sh
