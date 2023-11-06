#!/bin/bash

cd /data/Software/mydan/Connector/pp/device/crontab/bind-tree-from-outside || exit 1

if [ ! -f addr ];then
    echo skip
    exit
fi

addr=$(cat addr)

wget $addr  -O mount_info.txt

./sync.py
