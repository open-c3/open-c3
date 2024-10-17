#!/bin/bash
set -e

docker run --rm -i \
  --workdir /code \
  -v /data/open-c3/Connector/pp/k8s-manage/getK8sHealth:/code \
  -v /data/open-c3-data/golang-build/tmp/k8s-manage/getK8sHealth:/go golang:1.22 \
   go build -o c3mc-service-analysis-get-k8s-health main.go
