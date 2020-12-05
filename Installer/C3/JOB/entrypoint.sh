#!/bin/bash

if [ "X$OPEN_C3_EXIP" == "X" ];then
    echo "env OPEN_C3_EXIP undef"
    exit 1;
fi

if [ ! -f /data/Software/mydan/etc/agent/auth/c3_test.key ]; then
    cd /data/Software/mydan/etc/agent/auth && \
    ssh-keygen -f c3_test -P "" && \
    mv c3_test c3_test.key && \
    echo success
fi

nginx
crond

/data/Software/mydan/Connector/restart-open-c3-auto-config-change.pl
