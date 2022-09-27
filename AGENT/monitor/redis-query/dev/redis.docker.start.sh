#!/bin/bash

docker run -id -p 6379:6379 --privileged=true -e LANG="C.UTF-8" --name redis-query-redis-dev redis
