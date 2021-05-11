#!/bin/bash

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
    version=$(date +%Y%m%d.%H%M%S)
    echo "[INFO]backup to $version ..."
    docker exec -i openc3-mysql mysqldump -h127.0.0.1 -uroot -popenc3123456^! --databases jobs jobx ci agent connector > openc3.${version}.sql
    echo "[SUCC]backup done."
}

function recovery() {
    version=$1
    echo =================================================================
    echo "[INFO]recovery to $version ..."
    docker exec -i openc3-mysql mysql -h127.0.0.1 -uroot -popenc3123456^! < openc3.${version}.sql
    echo "[SUCC]recovery done."
}

case "$1" in
list)
    list
    ;;
backup)
    backup
    ;;
recovery)
    recovery $2
    ;;
*)
    echo "Usage: $0 {list|backup|recovery}"
    echo "$0 recovery YYYYmmdd.HHMMSS"
    exit 2
esac
