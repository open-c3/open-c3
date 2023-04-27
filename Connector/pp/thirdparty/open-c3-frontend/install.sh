#!/bin/bash
cp v2.nginx.conf v.nginx.conf 
docker exec openc3-server nginx -s reload
./upgrade.sh
