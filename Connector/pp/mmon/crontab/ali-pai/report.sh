#!/bin/bash

cd /data/Software/mydan/Connector/pp/mmon/crontab/ali-pai || exit

if [ ! -f config.txt ]; then
    exit
fi

day=1

if [ "X$1" != "X" ];then
    day=$1
fi

Date=$(date -d "$day day ago" "+%F")

cat config.txt |while read lines; do
    ./get.py  $Date $day $lines | c3mc-base-sendmesg alipai
done
