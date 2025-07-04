#!/bin/bash
set -e

C3BASEPATH=$( [[ "$(uname -s)" == Darwin ]] && echo "$HOME/open-c3-workspace" || echo "/data" )

docker run --rm -i \
  --workdir /code \
  -v $C3BASEPATH/open-c3/Connector/pp/k8s-manage/getK8sHealth:/code \
  -v $C3BASEPATH/open-c3/tmp/golang-build/tmp/k8s-manage/getK8sHealth:/go golang:1.23 \
   go build -o c3mc-service-analysis-get-k8s-health main.go
