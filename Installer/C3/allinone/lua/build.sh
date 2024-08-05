#!/bin/bash
set -x
set -e
docker build . -t openc3/basev2:t2204065-grafana-lua --no-cache
