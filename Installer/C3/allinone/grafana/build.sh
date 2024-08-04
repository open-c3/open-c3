#!/bin/bash
set -x
set -e

cp /data/open-c3/grafana/config/grafana.ini .
docker build . -t openc3/basev2:t2204065-grafana --no-cache
