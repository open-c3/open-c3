#!/bin/bash

/data/open-c3/Installer/scripts/databasectrl.sh  backup

mysql="docker exec -i openc3-mysql mysql -uroot -popenc3123456^!"

cat /data/open-c3/Installer/upgrade/v2.0.0/cleantemp.sql  | $mysql
cat /data/open-c3/*/schema.sql |grep -v 'create database' | $mysql
cat /data/open-c3/Installer/upgrade/v2.0.0/copydata.sql   | $mysql
