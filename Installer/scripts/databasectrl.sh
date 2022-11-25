#!/bin/bash

if [ "X$OpenC3_Backup_ContainersName" == "X" ]; then
    OpenC3_Backup_ContainersName=openc3-mysql
fi

BASE_PATH=/data/open-c3-data/backup/mysql
mkdir -p $BASE_PATH
cd $BASE_PATH || exit 1

function list() {
    echo =================================================================
    echo "[INFO]list ..."
    ls|awk -F '.' '{print $2"."$3}'
}

function backup() {
    echo =================================================================
    version=$(date +%y%m%d.%H%M%S)
    if [ "X$1" != "X" ];then
        version=$1
    fi
    echo "[INFO]backup to $version ..."
    docker exec -i $OpenC3_Backup_ContainersName mysqldump -h127.0.0.1 -uroot -popenc3123456^! --databases jobs jobx ci agent connector > openc3.${version}.sql
    echo "[SUCC]backup done."
}

function recovery() {
    version=$1
    echo =================================================================
    echo "[INFO]recovery to $version ..."
    docker exec -i $OpenC3_Backup_ContainersName mysql -h127.0.0.1 -uroot -popenc3123456^! < openc3.${version}.sql
    echo "[SUCC]recovery done."
}

case "$1" in
list)
    list
    ;;
backup)
    backup $2
    ;;
recovery)
    recovery $2
    ;;
*)
    echo "Usage: $0 {list|backup|recovery}"
    echo "$0 recovery YYYYmmdd.HHMMSS"
    exit 2
esac
