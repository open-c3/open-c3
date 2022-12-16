#!/bin/bash

#!/bin/bash
set -e

docker run --rm -i \
  --workdir /code \
  -v /data/open-c3/Connector/bl/jumpserver:/code \
  -v /data/open-c3/Connector/bl/jumpserver/tmp:/go golang:1.17.10 \
   go build -o c3mc-bl-jumpserver main.go
