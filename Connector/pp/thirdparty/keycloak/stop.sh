#!/bin/bash

docker stop openc3-keycloak
docker rm   openc3-keycloak

docker exec openc3-server cp /data/Software/mydan/c3-front/nginxconf/open-c3.keycloak.conf-off /etc/nginx/conf.d/open-c3.keycloak.conf
docker exec openc3-server nginx -s reload
