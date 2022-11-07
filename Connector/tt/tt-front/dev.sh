#!/bin/bash

BASE_PATH=/data/open-c3

GITADDR=http://github.com
DOCKERINSTALL=https://get.docker.com
if [ "X$OPENC3_ZONE" == "XCN"  ]; then
    GITADDR=http://gitee.com
    DOCKERINSTALL=https://get.daocloud.io/docker
fi

function start() {

    IP=$1
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
    echo "[INFO]synchronize the dependent part of c3-front ..."

    if [ "X$IP" = "X0.0.0.0" ];then
        echo =================================================================
        echo "[INFO]build ..."

        docker run --rm -i -v /data/open-c3/Connector/tt/tt-front/:/code openc3/gulp bower install --allow-root
        docker run --rm -i -v /data/open-c3/Connector/tt/tt-front/:/code openc3/gulp npm   install --unsafe-perm 
        docker run --rm -i -v /data/open-c3/Connector/tt/tt-front/:/code openc3/gulp gulp  build
        mkdir -p /data/open-c3/c3-front/dist/tt/
        rsync -av /data/open-c3/Connector/tt/tt-front/dist/               /data/open-c3/c3-front/dist/tt/ --delete
        rsync -av /data/open-c3/Connector/tt/tt-front/src/assets/images/  /data/open-c3/c3-front/dist/assets/images/
        
        exit
    fi

    echo =================================================================
    echo "[INFO]start web ..."

    docker run -itd -v /data/open-c3/Connector/tt/tt-front/:/code  -p 3003:3000 --name open-c3-tt-web-dev --add-host=open-c3.org:$IP openc3/gulp gulp serve
    if [ $? = 0 ]; then
        echo "[SUCC]start web success."
    else
        echo "[FAIL]start web fail."
        exit 1
    fi

    echo "[SUCC]openc-c3-cmdb-tt web start successfully."

    echo =================================================================
    echo "Web page: http://localhost:3003"
}

function stop() {
    echo =================================================================
    echo "[INFO]stop ..."

    docker kill open-c3-tt-web-dev;docker rm open-c3-tt-web-dev

    echo "[SUCC]stoped."
}

function startlocal() {
    IP=$(ifconfig |grep inet|grep netmask|grep -v 'inet 127'|grep -v 'inet 172'|awk '{print $2}'|head -n 1)
    echo "IP: $IP"
    start $IP
}

function init() {
    rm -rf /data/open-c3/Connector/tt/tt-front/node_modules
    cp -r /data/open-c3/c3-front/node_modules /data/open-c3/Connector/tt/tt-front/node_modules
    chmod 777 /data/open-c3/Connector/tt/tt-front/node_modules -R
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
startlocal)
    startlocal
    ;;
restart)
    stop
    startlocal
    ;;
init)
    init
    ;;
*)
    echo "Usage: $0 {start|stop|build|startlocal|restart|init}"
    echo "$0 start 10.10.10.10(open-c3 api IP)"
    exit 2
esac
