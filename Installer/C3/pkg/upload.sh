#!/bin/bash
set -e

cd /data/open-c3/Installer/C3/pkg || exit

echo "c3bot auto pkg" > upload.txt

git status .|grep /version|awk '{print $NF}'|awk -F/ '{print $1}' |grep -f module |xargs -i{} bash -c "./upload-module.sh {} || exit 255"

git commit -m "`cat upload.txt`"
