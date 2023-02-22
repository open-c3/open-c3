#!/bin/bash
set -e

docker run --rm -i \
  --workdir /code \
  -v /data/open-c3/Connector/bl/sync/jumpserver:/code \
  -v /data/open-c3/Connector/bl/sync/jumpserver/tmp:/go golang:1.17.10 \
   go build -o jumpserver main.go
