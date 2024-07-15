#!/bin/bash
set -e

docker run --rm -i \
  --workdir /code \
  -v /data/open-c3/Connector/pp/service-analysis/nginx:/code \
  -v /data/open-c3/Connector/pp/service-analysis/nginx/tmp:/go golang:1.22 \
   go build -o c3mc-service-analysis-get-nginx-conf main.go
