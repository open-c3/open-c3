#!/bin/bash

#!/bin/bash
set -e

docker run --rm -i \
  --workdir /code \
  -v /data/open-c3/Connector/bl:/code \
  -v /data/open-c3/Connector/bl/tmp:/go golang:1.17.10 \
   go build -o c3mc-create-ticket main.go
