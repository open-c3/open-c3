#!/bin/bash
set -e

mkdir -p /data/Software/mydan/PKG /data/logs /data/ci-scripts

if [ "X$USRNAME" != "X" ]; then
    mkdir -p /etc/cron.d.$USRNAME
    chown $USRNAME.$USRNAME /etc/cron.d.$USRNAME
    chown $USRNAME.$USRNAME /data/Software/mydan /data/logs /data/glusterfs /data/ci-scripts -R
fi
