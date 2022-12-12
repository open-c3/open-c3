#!/bin/bash
docker exec -it openc3-server curl -XPOST http://openc3-prometheus:9090/-/reload
