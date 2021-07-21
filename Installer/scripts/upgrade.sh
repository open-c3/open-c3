#!/bin/bash

BASE_PATH=/data/open-c3
cd $BASE_PATH || exit 1

function upgradeSelf() {

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

    ./Installer/scripts/single.sh reload
}

function upgradeCluster() {

    Cluster=$1
    Version=$(date +%Y%m%d%H%M)
    echo =================================================================
    echo "[INFO]upgrade Cluster $Cluster ..."

    ./Installer/scripts/cluster.sh deploy -e $Cluster -v $Version
}

if [ "X$1" == "X" ]; then
    upgradeSelf
else
    upgradeCluster $1
fi
