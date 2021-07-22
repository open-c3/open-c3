#!/bin/bash

function backup() {
    echo =================================================================
    echo "[INFO]backup ..."
    cd /data && tar -zcvf open-c3-data.tar.gz open-c3-data --exclude open-c3-data/mysql-data
    echo "[SUCC]backup done."
}

function recovery() {
    echo =================================================================
    echo "[INFO]recovery ..."
    cd /data && tar -zxvf open-c3-data.tar.gz
    echo "[SUCC]recovery done."
}

case "$1" in
backup)
    backup
    ;;
recovery)
    recovery $2
    ;;
*)
    echo "Usage: $0 {backup|recovery}"
    echo "$0 recovery"
    exit 2
esac
