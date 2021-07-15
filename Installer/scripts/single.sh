#!/bin/bash

BASE_PATH=/data/open-c3

GITADDR=http://github.com
if [ "X$OPENC3_ZONE" == "XCN"  ]; then
    GITADDR=http://gitee.com
fi

function install() {

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
    echo "[INFO]create Installer/C3/.env"

    if [ "X$1" != "X" ]; then
        echo $1 |grep "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$" > /dev/null
        if [ $? = 0 ]; then
            random=$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM
            name="test"
            if [ "X$OPEN_C3_NAME" != "X" ];then
                name=$OPEN_C3_NAME
            fi
            echo "OPEN_C3_RANDOM=$random" > $BASE_PATH/Installer/C3/.env
            echo "OPEN_C3_EXIP=$1" >> $BASE_PATH/Installer/C3/.env
            echo "OPEN_C3_NAME=$name" >> $BASE_PATH/Installer/C3/.env
        else
            echo "$0 install 10.10.10.10(Your Internet IP)"
            exit 1
        fi
    else
        echo "$0 install 10.10.10.10(Your Internet IP)"
        exit 1
    fi

    if [ -f "$BASE_PATH/Installer/C3/.env" ]; then
        echo "[SUCC]create $BASE_PATH/Installer/C3/.env success."
    else
        echo "[FAIL]create $BASE_PATH/Installer/C3/.env fail."
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
        echo "[SUCC]docker is started."
    else
        echo "[FAIL]start docker fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]enable docker.service ..."
    systemctl enable docker.service
    if [ $? = 0 ]; then
        echo "[SUCC]enable docker.service success."
    else
        echo "[FAIL]enable docker.service fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]get open-c3-install-cache ..."

    if [ ! -d "$BASE_PATH/Installer/install-cache" ]; then
        cd $BASE_PATH/Installer && git clone $GITADDR/open-c3/open-c3-install-cache install-cache
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
    echo "[INFO]create c3-front/dist/book ..."

    rm -rf $BASE_PATH/c3-front/dist/book
    cd $BASE_PATH/c3-front/dist && git clone $GITADDR/open-c3/open-c3.github.io book

    if [ -d "$BASE_PATH/c3-front/dist/book" ]; then
        echo "[SUCC]create c3-front/dist/book success."
    else
        echo "[FAIL]create c3-front/dist/book fail."
        exit 1
    fi

    cd $BASE_PATH || exit 1

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

    if [ -d "$BASE_PATH/Installer/install-cache/MYDan" ]; then
        rsync -av $BASE_PATH/Installer/install-cache/MYDan/ $BASE_PATH/MYDan/
        if [ $? = 0 ]; then
            echo "[SUCC]rsync MYDan from install-cache success."
        else
            echo "[FAIL]rsync MYDan from install-cache fail."
            exit 1
        fi
    else
        cd $BASE_PATH/MYDan && git clone https://github.com/MYDan/repo
        cd $BASE_PATH

        if [ -d "$BASE_PATH/MYDan/repo" ]; then
            echo "[SUCC]get MYDan success."
        else
            echo "[FAIL]get MYDan fail."
            exit 1
        fi

    fi

    echo =================================================================
    echo "[INFO]sync MYDan/repo ..."

    if [ -d "$BASE_PATH/Installer/install-cache/MYDan" ]; then
        echo "[INFO]rsync MYDan from install-cache done. skip"
    else
        cd $BASE_PATH/MYDan/repo/scripts && SYNC_MYDan_VERSION=20201213220001:10108f7303adc9992db663bfd99ddf1b ./sync.sh
        cd $BASE_PATH

        if [ $? = 0 ]; then
            echo "[SUCC]sync MYDan/repo success."
        else
            echo "[FAIL]sync MYDan/repo fail."
            exit 1
        fi
    fi

    echo "[SUCC]openc-c3 installed successfully."

    echo =================================================================
    echo "Web page: http://$1"
    echo "User: open-c3"
    echo "Password: changeme"

    echo "[INFO]Run command to start service: $0 start"

}

function start() {
    echo =================================================================
    echo "[INFO]start ..."

    cd $BASE_PATH/Installer/C3/ && ../docker-compose up -d

    echo "[SUCC]started."
}

function stop() {
    echo =================================================================
    echo "[INFO]stop ..."

    cd $BASE_PATH/Installer/C3/ && ../docker-compose kill

    echo "[SUCC]stoped."
}

function restart() {
    echo =================================================================
    echo "[INFO]restart ..."
    Date=$(date "+%F %H:%M:%S")
    echo "#$Date" >> $BASE_PATH/Connector/config.ini/current 

    echo "[SUCC]The operation is complete and the service will restart in a few seconds."
}

function check() {
    module=$1
    X=$(curl localhost/api/$module/mon 2>/dev/null)
    if [ "X$X" = "Xok" ]; then
        echo "[SUCC]module $module up."
    else
        echo "[FAIL]module $module down."
    fi
}

function status() {
    echo =================================================================
    check connector
    check agent
    check job
    check jobx
    check ci
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
status)
    status
    ;;
restart)
    restart
    ;;
*)
    echo "Usage: $0 {start|stop|status|restart|install}"
    echo "$0 install 10.10.10.10(Your Internet IP)"
    exit 2
esac
