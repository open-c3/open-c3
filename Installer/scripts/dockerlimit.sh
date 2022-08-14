#!/bin/bash

docker ps -a|awk '{print $1}'|grep -v CONTAINER|xargs  -i{} docker update --cpus=2 {}

docker update -c 4000  openc3-server
docker update -c 4000  openc3-mysql

docker update -c 3000  openc3-lua
docker update -c 3000  openc3-grafana
docker update -c 3000  openc3-prometheus
docker update -c 3000  openc3-alertmanager

docker update -c 2000  openc3-localbashv2

#docker run -it -m 200M --memory-swap=300m progrium/stress --vm 1 --vm-bytes 208m
#docker run -it progrium/stress --cpu 8

#seq 1 10|xargs -i{} bash -c "docker run -d -m 15g --oom-kill-disable  progrium/stress --vm 8 --vm-bytes 100m"

#docker update -m 5g --oom-kill-disable  openc3-server
#docker update -m 2g --oom-kill-disable  openc3-mysql
