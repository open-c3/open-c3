#!/bin/bash
set -e

C3BASEPATH=$( [[ "$(uname -s)" == Darwin ]] && echo "$HOME/open-c3-workspace" || echo "/data" )

docker run --rm -i \
  --workdir /code \
  -v $C3BASEPATH/open-c3/Connector/pp/service-analysis/nginx:/code \
  -v $C3BASEPATH/open-c3/tmp/golang-build/tmp/service-analysis/nginx:/go golang:1.22 \
   go build -o c3mc-service-analysis-get-nginx-conf main.go
