#!/bin/bash

DOCKERINSTALL=https://get.docker.com
if [ "X$OPENC3_ZONE" == "XCN"  ]; then
    DOCKERINSTALL=https://get.daocloud.io/docker
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
echo "[INFO]enable docker.service ..."
systemctl enable docker.service
if [ $? = 0 ]; then
    echo "[SUCC]enable docker.service success."
else
    echo "[FAIL]enable docker.service fail."
    exit 1
fi

echo =================================================================
echo "[INFO]create newwork ..."
X=$(docker network ls|awk '{print $2}'|grep ^c3_JobNet$|wc -l)
if [ "X$X" == "X0" ];then
    echo "create ..."
    docker network create --driver bridge --subnet 172.26.0.0/16 --gateway 172.26.0.1 c3_JobNet
else
    echo "skip."
fi
