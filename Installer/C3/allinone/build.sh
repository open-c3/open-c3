#!/bin/bash
rm -rf temp
mkdir -p temp

cat /data/open-c3/*/schema.sql  /data/open-c3/Installer/C3/mysql/init.sql > temp/init.sql

cp ../mysql/conf/my.cnf temp/
cp -r /data/open-c3/Connector temp/
cp -r /data/open-c3/MYDan temp/
cp -r /data/open-c3/JOBX temp/
cp -r /data/open-c3/JOB temp/
cp -r /data/open-c3/AGENT temp/
cp -r /data/open-c3/CI temp/
cp -r /data/open-c3/c3-front temp/
cp -r /data/open-c3/web-shell temp/

cp -r /data/open-c3-data/mysql-data temp/mysql-data

VERSION=$1
echo VERSION:$VERSION
docker build . -t openc3/allinone:$VERSION
rm -rf temp

docker run --env OPEN_C3_EXIP=10.60.77.50 --env OPEN_C3_NAME=test -p 8080:88 -p 8081:3388 -h openc3-srv-docker  -it openc3/allinone:$VERSION
