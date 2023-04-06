#!/bin/bash

if [ "X$OPEN_C3_EXIP" == "X" ];then
    echo "env OPEN_C3_EXIP undef"
    exit 1;
fi

if [ "X$OPEN_C3_NAME" == "X" ];then
    echo "env OPEN_C3_NAME undef"
    exit 1;
fi

ooze=/data/open-c3-data/lotus/ooze
nenv=/data/open-c3-data/lotus/env

if [ -f $ooze ]; then

    BAKPATH=/data/open-c3-data/lotus/$(date +%s)
    mkdir -p $BAKPATH
    cp -r /data/Software/mydan/etc/agent/auth  $BAKPATH/

    rm /data/Software/mydan/etc/agent/auth/c3_${OPEN_C3_NAME}.key
    rm /data/Software/mydan/etc/agent/auth/c3_${OPEN_C3_NAME}.pub

    random=$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM
    echo "OPEN_C3_RANDOM=$random"         > $nenv
    echo "OPEN_C3_EXIP=$OPEN_C3_EXIP"    >> $nenv
    echo "OPEN_C3_NAME=$OPEN_C3_NAME"    >> $nenv

    rm -f $ooze
fi


if [ -f $nenv ]; then
    . $nenv
fi

if [ ! -f /data/Software/mydan/etc/agent/auth/c3_${OPEN_C3_NAME}.key ]; then
    cd /data/Software/mydan/etc/agent/auth && \
    ssh-keygen -f c3_${OPEN_C3_NAME} -P "" && \
    mv c3_${OPEN_C3_NAME} c3_${OPEN_C3_NAME}.key && \
    echo success
fi

nginx
crond

mkdir -p /data/open-c3-data/glusterfs/fileserver

/data/Software/mydan/Connector/restart-open-c3-auto-config-change.pl
