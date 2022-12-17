#!/bin/bash
set -e

./build.sh
docker  exec -it openc3-server bash -c "/data/Software/mydan/Connector/tt/trouble-ticketing/tdev.sh"
