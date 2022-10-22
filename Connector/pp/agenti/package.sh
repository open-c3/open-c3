#!/bin/bash

addr=$(cat .addr)

if [ "X" == "X$addr" ];then
    echo nofind .addr
    exit 1
fi

curl -L $addr/api/scripts/installAgent.sh    | sudo OPEN_C3_ADDR=$addr bash
curl -L $addr/api/scripts/installAgentMon.sh | sudo OPEN_C3_ADDR=$addr bash
curl -L $addr/api/scripts/package.sh         | sudo OPEN_C3_ADDR=$addr bash

cp /data/openc3.agent.20210819110502.Linux.x86_64 /data/open-c3/AGENT/scripts/
