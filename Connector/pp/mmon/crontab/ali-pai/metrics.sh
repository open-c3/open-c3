#!/bin/bash

cd /data/Software/mydan/Connector/pp/mmon/crontab/ali-pai || exit

if [ ! -f config.txt ]; then
    exit
fi

Date=$(date -d "1 day ago" "+%F")

> metrics.temp.$$
cat config.txt |while read lines; do
    ALI_PAI_Metrics=1 ./get.py  $Date 0 $lines >> metrics.temp.$$
done


mv metrics.temp.$$ /data/Software/mydan/Connector/local/alipaimetrics.txt.temp
mv /data/Software/mydan/Connector/local/alipaimetrics.txt.temp /data/Software/mydan/Connector/local/alipaimetrics.txt
