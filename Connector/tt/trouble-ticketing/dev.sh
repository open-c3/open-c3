#!/bin/bash
set -e

docker run --rm -i \
  --workdir /code \
  -v /data/open-c3/Connector/tt/trouble-ticketing:/code \
  -v /data/open-c3/Connector/tt/trouble-ticketing/tmp:/go golang:1.17.10 \
   go build -o trouble-ticketing main.go

docker  exec -it openc3-server bash -c "/data/Software/mydan/Connector/tt/trouble-ticketing/tdev.sh"
