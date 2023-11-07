#!/bin/bash

cd /data/open-c3/Installer/C3 || exit 1

srv=$1

if [ "X$srv" == "X" ];then
    echo $0 ServerName
    docker ps|awk '{print $NF}'|grep openc3-[a-z]*$
    exit 1

fi
../docker-compose  up -d --build $srv
