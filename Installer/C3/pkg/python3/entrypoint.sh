#!/bin/bash
set -e

if [ "X$1" == "Xbash" ]; then
    exec bash
fi

cp /app/python3.tar.gz /tempdata/
