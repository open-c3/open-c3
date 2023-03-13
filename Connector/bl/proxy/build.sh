#!/bin/bash
set -e

docker run --rm -i \
  --workdir /code \
  -v /data/open-c3/Connector/bl/proxy:/code \
  -v /data/open-c3/Connector/bl/proxy/tmp:/go golang:1.17.10 \
   go build -o c3-proxy main.go
