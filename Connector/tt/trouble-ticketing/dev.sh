#!/bin/bash
set -e

/data/open-c3/Connector/tt/trouble-ticketing/build.sh
docker  exec -it openc3-server bash -c "/data/Software/mydan/Connector/tt/trouble-ticketing/tdev.sh"
