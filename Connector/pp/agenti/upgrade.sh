#!/bin/bash

addr=$(cat .addr)

if [ "X" == "X$addr" ];then
    echo nofind .addr
    exit 1
fi

wget $addr/api/scripts/openc3.agent.20210819110502.Linux.x86_64 -O openc3.agent.20191021100002.Linux.x86_64
chmod +x openc3.agent.20191021100002.Linux.x86_64
