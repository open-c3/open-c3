#!/bin/bash

mkdir -p /data/open-c3-data/glusterfs/maintain
cd /data/open-c3-data/glusterfs/maintain || exit

mkdir -p  data/mysql

version=$(date +%y%m%d.%H%M%S)
/data/open-c3/Installer/scripts/databasectrl.sh  backup $version
cp /data/open-c3-data/backup/mysql/openc3.${version}.sql data/mysql/
