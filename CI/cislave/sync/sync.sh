#!/bin/bash

if [ ! -f /data/Software/mydan/CI/cislave/conf/master.yml ]; then
    echo skip
    exit
fi

cd /data/Software/mydan/CI/cislave/sync && ./sync
