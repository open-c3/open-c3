#!/bin/sh
set -e

if [ "X$1" == "Xsh" ]; then
    exec sh
fi

tar -zxvf /x.tar.gz -C /data
