#!/bin/bash

set -e

TEMP=/tmp/c3-cmdb-demo-$$
mkdir $TEMP
cd    $TEMP

cp -r /data/open-c3-data/device/curr .
rm -rf curr/auth curr/cache curr/conf curr/price curr/jumpserver

ls curr/*/*/data.tsv|xargs -i{} bash -c "sed -i '3,$ d' {}"

tar -zcf cmdb-demo.tar.gz curr

UUID=xxx
if [ "X$1" != "X" ]; then
    UUID=$1
fi

mv cmdb-demo.tar.gz /data/open-c3/c3-front/dist/cmdb-demo.$UUID.tar.gz

rm -rf $TEMP
