#!/bin/bash
cp v1.nginx.conf v.nginx.conf 
docker exec openc3-server nginx -s reload
