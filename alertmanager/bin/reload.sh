#!/bin/bash
docker exec -it openc3-server curl -XPOST http://openc3-alertmanager:9093/-/reload
