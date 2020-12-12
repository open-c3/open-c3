#!/bin/bash

BASE_PATH=/data/open-c3

function init() {

    echo =================================================================
    echo "[INFO]check the environment ..."

    if [[ -d "$BASE_PATH" && -d "$BASE_PATH/Installer/install-cache" && -d "$BASE_PATH/c3-front/dist" && -d "$BASE_PATH/web-shell/node_modules" && -d "$BASE_PATH/MYDan/repo" ]]; then
        echo "[SUCC]environment ok."
    else
        echo "[FAIL]You need to install a single environment first."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]install sshpass ..."

    sshpass --help 1>/dev/null 2>&1 || yum install -y sshpass
    sshpass 1>/dev/null 2>&1
    if [ $? = 0 ]; then
        echo "[SUCC]sshpass installed."
    else
        echo "[FAIL]install sshpass fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]check perl ..."

    stat=0
    if [ ! -f /opt/mydan/perl/bin/perl ];then
        echo "[INFO]install perl ..."
        curl https://raw.githubusercontent.com/MYDan/perl/master/scripts/install.sh |bash
        stat=$1
    fi
    if [ $? = 0 ]; then
        echo "[SUCC]perl ok."
    else
        echo "[FAIL]perl fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]init ..."

    if [ "X$1" != "X" ]; then
        exec $BASE_PATH/Installer/cluster/init.pl $1
    else
        echo "$0 init foo (Cluster Name)"
        exit 1
    fi
}

function deploy() {
    exec $BASE_PATH/Installer/cluster/deploy.pl $@
}

case "$1" in
init)
    init $2
    ;;
deploy)
    deploy $@
    ;;
*)
    echo "Usage: $0 {init|deploy}"
    echo "$0 init foo (Cluster Name)"
    exit 2
esac
