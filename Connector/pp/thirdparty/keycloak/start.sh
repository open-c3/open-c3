#!/bin/bash

docker run \
  -d \
  --restart=always \
  -v /data/open-c3-data/keycloak-data/data/:/opt/jboss/keycloak/standalone/data/ \
  --network c3_JobNet \
  -e KEYCLOAK_USER=admin \
  -e KEYCLOAK_PASSWORD=admin \
  -e PROXY_ADDRESS_FORWARDING=true \
  --name openc3-keycloak \
  openc3-keycloak

docker exec openc3-server cp /data/Software/mydan/c3-front/nginxconf/open-c3.keycloak.conf-on /etc/nginx/conf.d/open-c3.keycloak.conf
docker exec openc3-server nginx -s reload
