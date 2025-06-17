#!/bin/bash
set -ex

cp /data/open-c3/grafana/config/grafana.ini .

rm -rf grafana-9.0.1
mkdir  grafana-9.0.1

docker stop g9 2>/dev/null|| :

docker run --rm -d --name g9 grafana/grafana:9.0.1

docker cp g9:/usr/share/grafana grafana-9.0.1/usr_share_grafana
docker cp g9:/etc/grafana grafana-9.0.1/etc_grafana
docker cp g9:/var/lib/grafana/plugins grafana-9.0.1/var_lib_grafana_plugins

docker build . -t openc3/basev2:t2206131-grafana --no-cache

rm -rf grafana-9.0.1
docker stop g9
