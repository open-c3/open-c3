#!/bin/bash
set -e

./control  build
docker  exec -it openc3-server bash -c "cd /data/Software/mydan/Connector/tt/trouble-ticketing && ./trouble-ticketing"
