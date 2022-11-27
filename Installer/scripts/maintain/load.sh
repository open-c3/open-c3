#!/bin/bash

version=$1

if [ "X$version" == "X" ];then
    echo nofind version, \$0 version
    ls /data/open-c3-data/glusterfs/maintain/data/mysql|sed 's/^openc3.//'|sed 's/.sql//'
    exit
fi

./load-1-base.sh
./load-2-db.sh $version
./load-3-log.sh
