#!/bin/bash

#TODO FENG
export OPEN_C3_EXIP='10.10.1.1'

if [ "X$OPEN_C3_EXIP" == "X" ];then
    echo "env OPEN_C3_EXIP undef"
    exit 1;
fi

nginx
crond

/data/Software/mydan/Connector/restart-open-c3-auto-config-change.pl
