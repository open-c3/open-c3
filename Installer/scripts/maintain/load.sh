#!/bin/bash

version=$1

if [ "X$version" == "X" ];then
    echo nofind version
    exit
fi

./load-1-base.sh
./load-2-db.sh $version
./load-3-log.sh
