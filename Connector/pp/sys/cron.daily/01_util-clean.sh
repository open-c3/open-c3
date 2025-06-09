#!/bin/bash
docker images|grep '<none>'|awk '{print $3}'|xargs -i{} docker rmi {}
docker ps -a|grep openc3ci|grep -v 'Exited (0)'|awk '{print $1}'|xargs -i{} docker rm {}
#docker system prune
