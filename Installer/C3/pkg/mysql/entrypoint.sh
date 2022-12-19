#!/bin/bash
set -e

if [ "X$1" == "Xbash" ]; then
    exec bash
fi

cp /usr/bin/mysql /tempdata/
