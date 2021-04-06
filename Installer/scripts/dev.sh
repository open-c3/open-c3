#!/bin/bash

BASE_PATH=/data/open-c3

function start() {

    IP=$1
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
    echo "[INFO]check ..."

    if [ "X$1" != "X" ]; then
        echo $1 |grep "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$" > /dev/null
        if [ $? != 0 ]; then
            echo "$0 start 10.10.10.10(open-c3 api IP)"
            exit 1
        fi
    else
        echo "$0 start 10.10.10.10(open-c3 api IP)"
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
        echo "[SUCC]docker is started."
    else
        echo "[FAIL]start docker fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]get open-c3-dev-cache ..."

    if [ ! -d "$BASE_PATH/Installer/dev-cache" ]; then
        cd $BASE_PATH/Installer && git clone https://github.com/open-c3/open-c3-dev-cache dev-cache
        cd $BASE_PATH
    fi

    if [ -d "$BASE_PATH/Installer/dev-cache" ]; then
        echo "[SUCC]get open-c3-dev-cache success."
    else
        echo "[FAIL]get open-c3-dev-cache fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]synchronize the dependent part of c3-front ..."

    rsync -av $BASE_PATH/Installer/dev-cache/c3-front/ $BASE_PATH/c3-front/

    if [ $? = 0 ]; then
        echo "[SUCC]synchronize success."
    else
        echo "[FAIL]synchronize fail."
        exit 1
    fi

    if [ "X$IP" = "X0.0.0.0" ];then
        echo =================================================================
        echo "[INFO]build ..."
        rm -rf $BASE_PATH/c3-front/dist
        docker run -it -v /data/open-c3/c3-front/:/code openc3/gulp gulp build
        cd $BASE_PATH/c3-front/dist && git clone https://github.com/open-c3/open-c3.github.io book

        git log --pretty=format:'%ai - %s' > $BASE_PATH/Connector/.versionlog

        exit
    fi

    echo =================================================================
    echo "[INFO]start web ..."

    docker run -itd -v /data/open-c3/c3-front/:/code  -p 3000:3000 --name open-c3-web-dev --add-host=open-c3.org:$IP openc3/gulp gulp serve
    if [ $? = 0 ]; then
        echo "[SUCC]start web success."
    else
        echo "[FAIL]start web fail."
        exit 1
    fi

    echo "[SUCC]openc-c3 web start successfully."

    echo =================================================================
    echo "Web page: http://localhost:3000"
}

function stop() {
    echo =================================================================
    echo "[INFO]stop ..."

    docker kill open-c3-web-dev;docker rm open-c3-web-dev

    echo "[SUCC]stoped."
}

case "$1" in
start)
    start $2
    ;;
stop)
    stop
    ;;
build)
    start 0.0.0.0
    ;;
*)
    echo "Usage: $0 {start|stop|build}"
    echo "$0 start 10.10.10.10(open-c3 api IP)"
    exit 2
esac
