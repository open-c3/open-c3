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
    echo "[INFO]get open-c3 ..."
    if [ ! -d $BASE_PATH ]; then
        cd /data && git clone $GITADDR/open-c3/open-c3
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

    docker --help 1>/dev/null 2>&1 || curl -fsSL $DOCKERINSTALL | bash
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
        cd $BASE_PATH/Installer && git clone $GITADDR/open-c3/open-c3-dev-cache dev-cache
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

        docker run --rm -i -v /data/open-c3/c3-front/:/code openc3/gulp bower install --allow-root
        docker run --rm -i -v /data/open-c3/c3-front/:/code openc3/gulp gulp build
        
        frontendstyleisjuyun=$(grep '^frontendstyle: juyun' $BASE_PATH/Connector/config.inix | wc -l)
        if [ "X$frontendstyleisjuyun" == "X1" ];then
            sed -i 's/openc3_style_ctrl=\\"[a-zA-Z0-9]*\\"/openc3_style_ctrl=\\"juyun\\"/g' $BASE_PATH/c3-front/dist/scripts/*
            sed -i 's/#f63/#3b3677/g' $BASE_PATH/c3-front/dist/scripts/*
            sed -i 's/#f63/#3b3677/g' $BASE_PATH/c3-front/dist/styles/*
            sed -i 's/#e52/#293fbb/g' $BASE_PATH/c3-front/dist/styles/*
        else
            sed -i 's/openc3_style_ctrl=\\"[a-zA-Z0-9]*\\"/openc3_style_ctrl=\\"openc3\\"/g' $BASE_PATH/c3-front/dist/scripts/*
            sed -i 's/#3b3677/#f63/g' $BASE_PATH/c3-front/dist/scripts/*
            sed -i 's/#3b3677/#f63/g' $BASE_PATH/c3-front/dist/styles/*
            sed -i 's/#293fbb/#e52/g' $BASE_PATH/c3-front/dist/styles/*
        fi

        openc3_job_system_only=$(grep "^openc3_job_system_only: '1'" $BASE_PATH/Connector/config.inix | wc -l)
        if [ "X$openc3_job_system_only" == "X1" ];then
            sed -i 's/openc3_job_system_only=0/openc3_job_system_only=1/g' $BASE_PATH/c3-front/dist/scripts/*
        else
            sed -i 's/openc3_job_system_only=1/openc3_job_system_only=0/g' $BASE_PATH/c3-front/dist/scripts/*
        fi

        openc3_monitor_monagent9100=$(grep "^monagent9100: '1'" $BASE_PATH/Connector/config.inix | wc -l)
        if [ "X$openc3_monitor_monagent9100" == "X1" ];then
            sed -i 's/openc3_monitor_monagent9100=0/openc3_monitor_monagent9100=1/g' $BASE_PATH/c3-front/dist/scripts/*
        else
            sed -i 's/openc3_monitor_monagent9100=1/openc3_monitor_monagent9100=0/g' $BASE_PATH/c3-front/dist/scripts/*
        fi

        rsync -av $BASE_PATH/c3-front/src/assets/ $BASE_PATH/c3-front/dist/assets/

        NEWBOOK=0
        if [ ! -d $BASE_PATH/c3-front/dist/book ];then
            NEWBOOK=1
        else

            GITBOOKINDEX=https://raw.githubusercontent.com/open-c3/open-c3.github.io/main/index.html
            if [ "X$OPENC3_ZONE" == "XCN"  ]; then
                GITBOOKINDEX=https://gitee.com/open-c3/open-c3.github.io/raw/main/index.html
            fi

            REMOTEUUID=$(curl $GITBOOKINDEX 2>/dev/null |md5sum |awk '{print $1}')
            LOCALUUID=$(md5sum $BASE_PATH/c3-front/dist/book/index.html 2>/dev/null |awk '{print $1}')
            if [ "X$REMOTEUUID" != "X$LOCALUUID" ];then
                NEWBOOK=1
            fi
        fi

        if [ "X$NEWBOOK" == "X1" ];then

            rm -rf $BASE_PATH/c3-front/dist/book.new
            rm -rf $BASE_PATH/c3-front/dist/book.old

            if [ -d /data/open-c3-book ]; then
                cp -r /data/open-c3-book $BASE_PATH/c3-front/dist/book.new
            else
                cd $BASE_PATH/c3-front/dist && git clone $GITADDR/open-c3/open-c3.github.io book.new || exit 1
            fi

            mv book book.old
            mv book.new book
        fi
        
        git log --pretty=format:'%ai - %s' |grep -v 'Merge branch' > $BASE_PATH/Connector/.versionlog
        git branch |grep ^*|awk '{print $2}' > $BASE_PATH/Connector/.versionname
        git rev-parse --short HEAD           > $BASE_PATH/Connector/.versionuuid
        date '+%F %H:%M:%S'                  > $BASE_PATH/Connector/.versiontime

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

function startlocal() {
    IP=$(ifconfig |grep inet|grep netmask|grep -v 'inet 127'|grep -v 'inet 172'|awk '{print $2}'|head -n 1)
    echo "IP: $IP"
    start $IP
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
*)
    echo "Usage: $0 {start|stop|build|startlocal|restart}"
    echo "$0 start 10.10.10.10(open-c3 api IP)"
    exit 2
esac
