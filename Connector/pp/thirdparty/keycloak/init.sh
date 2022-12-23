#!/bin/bash

docker build . -t openc3-keycloak:latest --no-cache

test  -d /data/open-c3-data/keycloak-data/data/kernel && exit
mkdir -p /data/open-c3-data/keycloak-data

docker run -d -e KEYCLOAK_USER=admin -e KEYCLOAK_PASSWORD=admin --name openc3-keycloak-tmp openc3-keycloak:latest
docker cp openc3-keycloak-tmp:/opt/jboss/keycloak/standalone/data/ /data/open-c3-data/keycloak-data/ 

chown 1000 -R  /data/open-c3-data/keycloak-data/data/ 
docker rm -f openc3-keycloak-tmp
