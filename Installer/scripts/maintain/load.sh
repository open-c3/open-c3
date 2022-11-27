#!/bin/bash

version=$1

if [ "X$version" == "X" ];then
    echo nofind version, \$0 version
    ls /data/open-c3-data/glusterfs/maintain/data/mysql|sed 's/^openc3.//'|sed 's/.sql//'
    exit
fi

touch /data/open-c3/Connector/c3.maintain
touch /data/open-c3/Connector/c3.maintain.flow
touch /data/open-c3/Connector/c3.maintain.mon

echo sleep 90 sec ...
sleep 90

./load-1-base.sh
./load-2-db.sh $version
./load-3-log.sh

docker restart openc3-server
