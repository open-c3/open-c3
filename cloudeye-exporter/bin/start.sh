#!/bin/bash

Config=/data/open-c3/cloudeye-exporter/conf/clouds.yml
test -f $Config || exit 1

docker run -d \
  -p 8087:8087 \
  --workdir=/ \
  -v /data/open-c3/cloudeye-exporter/conf/clouds.yml:/clouds.yml \
  --name openc3-cloudeye-exporter \
  finodigital/cloudeye-exporter
