#!/bin/bash

BASE_PATH=/data/open-c3

function install() {

    echo =================================================================
    echo "[INFO]get open-c3 ..."
    if [ ! -d $BASE_PATH ]; then
        cd /data && git clone https://github.com/open-c3/open-c3
    fi

    if [ -d "$BASE_PATH" ]; then
        echo "[SUCC]get open-c3 success."
    else
        echo "[FAIL]get open-c3 fail."
        exit 1
    fi

    cd $BASE_PATH || exit 1

    echo =================================================================
    echo "[INFO]create Connector/.env"

    if [ "X$1" != "X" ]; then
        echo $1 |grep "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$" > /dev/null
        if [ $? = 0 ]; then
            random=$(date +%N)
            echo "OPEN_C3_RANDOM=$random" > $BASE_PATH/Connector/.env
            echo "OPEN_C3_EXIP=$1" >> $BASE_PATH/Connector/.env
        else
            echo "$0 install 10.10.10.10(Your Internet IP)"
            exit 1
        fi
    else
        echo "$0 install 10.10.10.10(Your Internet IP)"
        exit 1
    fi

    if [ -f "$BASE_PATH/Connector/.env" ]; then
        echo "[SUCC]create $BASE_PATH/Connector/.env success."
    else
        echo "[FAIL]create $BASE_PATH/Connector/.env fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]create Connector/config.ini/current ..."

    if [ ! -f $BASE_PATH/Connector/config.ini/current ];then
        cp $BASE_PATH/Connector/config.ini/openc3 $BASE_PATH/Connector/config.ini/current
    fi

    if [ -f "$BASE_PATH/Connector/config.ini/current" ]; then
        echo "[SUCC]create Connector/config.ini/current success."
    else
        echo "[FAIL]create Connector/config.ini/current fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]install docker ..."

    docker --help 1>/dev/null 2>&1 || curl -fsSL https://get.docker.com | bash
    docker --help 1>/dev/null 2>&1
    if [ $? = 0 ]; then
        echo "[SUCC]docker installed."
    else
        echo "[FAIL]install docker fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]start docker ..."
    docker ps 1>/dev/null 2>&1 || service docker start
    docker ps 1>/dev/null 2>&1
    if [ $? = 0 ]; then
        echo "[SUCC] docker is started."
    else
        echo "[FAIL]start docker fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]get open-c3-install-cache ..."

    if [ ! -d "$BASE_PATH/Installer/install-cache" ]; then
        cd $BASE_PATH/Installer && git clone https://github.com/open-c3/open-c3-install-cache install-cache
        cd $BASE_PATH
    fi

    if [ -d "$BASE_PATH/Installer/install-cache" ]; then
        echo "[SUCC]get open-c3-install-cache success."
    else
        echo "[FAIL]get open-c3-install-cache fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]create c3-front/dist ..."

    if [ -d "$BASE_PATH/Installer/install-cache/c3-front/dist" ]; then
        rm -rf $BASE_PATH/c3-front/dist
        cp -r $BASE_PATH/Installer/install-cache/c3-front/dist $BASE_PATH/c3-front/dist
    else
        echo "[FAIL]nofind c3-front/dist in open-c3-install-cache."
    fi

    if [ -d "$BASE_PATH/c3-front/dist" ]; then
        echo "[SUCC]create c3-front/dist success."
    else
        echo "[FAIL]create c3-front/dist fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]create web-shell/node_modules ..."

    if [ -d "$BASE_PATH/Installer/install-cache/web-shell/node_modules" ]; then
        rm -rf $BASE_PATH/web-shell/node_modules
        cp -r $BASE_PATH/Installer/install-cache/web-shell/node_modules $BASE_PATH/web-shell/node_modules
    else
        echo "[FAIL]nofind web-shell/node_modules in open-c3-install-cache."
    fi

    if [ -d "$BASE_PATH/web-shell/node_modules" ]; then
        echo "[SUCC]create web-shell/node_modules success."
    else
        echo "[FAIL]create web-shell/node_modules fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]create Installer/C3/mysql/init/init.sql ..."

    cat $BASE_PATH/*/schema.sql > $BASE_PATH/Installer/C3/mysql/init/init.sql
    cat $BASE_PATH/Installer/C3/mysql/init.sql >> $BASE_PATH/Installer/C3/mysql/init/init.sql

    if [ -f "$BASE_PATH/Installer/C3/mysql/init/init.sql" ]; then
        echo "[SUCC]create Installer/C3/mysql/init/init.sql success."
    else
        echo "[FAIL]create Installer/C3/mysql/init/init.sql fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]get MYDan ..."

    mkdir -p $BASE_PATH/MYDan
    rm -rf $BASE_PATH/MYDan/repo

    cd $BASE_PATH/MYDan && git clone https://github.com/MYDan/repo
    cd $BASE_PATH

    if [ -d "$BASE_PATH/MYDan/repo" ]; then
        echo "[SUCC]get MYDan success."
    else
        echo "[FAIL]get MYDan fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]sync MYDan/repo ..."

    cd $BASE_PATH/MYDan/repo/scripts && ./sync.sh
    cd $BASE_PATH

    if [ $? = 0 ]; then
        echo "[SUCC]sync MYDan/repo success."
    else
        echo "[FAIL]sync MYDan/repo fail."
        exit 1
    fi

    echo "[SUCC]openc-c3 installed successfully."

    echo "Web page: http://$1"
    echo "User: open-c3"
    echo "Password: changeme"

}

function start() {
    echo =================================================================
    echo "[INFO]start ..."
    cd $BASE_PATH/Installer/C3/ && ../docker-compose up -d
}

function stop() {
    echo =================================================================
    echo "[INFO]stop ..."
    cd $BASE_PATH/Installer/C3/ && ../docker-compose kill
}

case "$1" in
install)
    install $2
    ;;
start)
    start
    ;;
stop)
    stop
    ;;
*)
    echo "Usage: $0 {start|stop|install}"
    echo "$0 install 10.10.10.10(Your Internet IP)"
    exit 2
esac
