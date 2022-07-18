#!/bin/bash

if [ "X$OPEN_C3_EXIP" == "X" ];then
    echo "env OPEN_C3_EXIP undef"
    exit 1;
fi

if [ "X$OPEN_C3_NAME" == "X" ];then
    echo "env OPEN_C3_NAME undef"
    exit 1;
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
