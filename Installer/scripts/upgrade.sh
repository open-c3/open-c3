#!/bin/bash

BASE_PATH=/data/open-c3
cd $BASE_PATH || exit 1

function upgradeSelf() {

    if [ "X$1" == "XSS" ];then
        echo =================================================================
        echo "[INFO]check version ..."
        BRANCH=$(git branch|grep ^*|awk '{print $2}'|grep "^v[0-9]*\.[0-9]*\.[0-9]*$")
        echo "VERSION: $BRANCH"

        CHECK=$(LANG=en git remote show origin |grep "^ *$BRANCH *pushes *to *$BRANCH"|grep '(local out of date)'|grep -v grep|wc -l)
        if [ "X0" == "X$CHECK" ]; then
            echo "No update required"
            exit;
        fi
    fi

    echo =================================================================
    echo "[INFO]git pull ..."

    git pull

    if [ $? = 0 ]; then
        echo "[SUCC]git pull success."
    else
        echo "[FAIL]git pull fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]install-cache pull ..."

    cd Installer/install-cache && git pull

    if [ $? = 0 ]; then
        echo "[SUCC]git pull success."
    else
        echo "[FAIL]git pull fail."
        exit 1
    fi

    cd $BASE_PATH || exit 1

    echo =================================================================
    echo "[INFO]c3-front build ..."

    ./Installer/scripts/dev.sh build

    if [ $? = 0 ]; then
        echo "[SUCC]c3-front build success."
    else
        echo "[FAIL]c3-front build fail."
        exit 1
    fi

    echo =================================================================
    echo "[INFO]reload open-c3 service ..."

    CTRL=restart
    if [[ "X$1" == "XS" || "X$1" == "XSS" ]];then
        CTRL=reload
    fi
    ./Installer/scripts/single.sh $CTRL
}

function upgradeCluster() {

    Cluster=$1
    Version=$(date +%Y%m%d%H%M)

    if [ "X$2" == "XS" ];then
        Version="S$Version"
    fi

    echo =================================================================
    echo "[INFO]upgrade Cluster $Cluster Version $Version..."

    ./Installer/scripts/cluster.sh deploy -e $Cluster -v $Version
}

if [[ "X$1" == "X" || "X$1" == "XS" || "X$1" == "XSS" ]]; then
    upgradeSelf $1
else
    upgradeCluster $1 $2
fi
