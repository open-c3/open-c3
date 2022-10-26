#!/bin/bash

UUID=$(date +%F.%H.%M.%S)
mkdir -p data
./dump -a conf/treealias | grep -v huawei-ecs-volume | ./ext-uuid  |sed 's/;/,/g' > data/treeinfo.$UUID.csv
