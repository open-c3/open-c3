#!/bin/bash
set -x
set -e
rm -rf temp
mkdir -p temp/c3-front

cat /data/open-c3/*/schema.sql  /data/open-c3/Installer/C3/mysql/init.sql > temp/init.sql

cp ../mysql/conf/my.cnf temp/
cp -r /data/open-c3/Connector temp/
cp -r /data/open-c3/MYDan temp/
cp -r /data/open-c3/JOBX temp/
cp -r /data/open-c3/JOB temp/
cp -r /data/open-c3/AGENT temp/
cp -r /data/open-c3/CI temp/
cp -r /data/open-c3/c3-front/dist temp/c3-front/dist
cp -r /data/open-c3/c3-front/nginxconf temp/c3-front/nginxconf
cp /data/open-c3/c3-front/nginx.conf temp/c3-front/nginx.conf
cp -r /data/open-c3/web-shell temp/
cp -r /data/open-c3/Installer/install-cache/bin temp/install-cache-bin

VERSION=$1
if [ "X$VERSION" == "X" ];then
    VERSION=$(date +%Y%m%d)
fi
echo VERSION:$VERSION
docker build . -t openc3/allinone:$VERSION
rm -rf temp

docker run -p 8080:88 -it openc3/allinone:$VERSION
