#!/bin/bash

docker run -d -p 3306:3306 --privileged=true  -e MYSQL_ROOT_PASSWORD=123456 -e LANG="C.UTF-8" --name mysql-query-mysql-dev mysql:5.7 
