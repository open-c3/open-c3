#!/bin/bash
set -e

if [ "X$1" == "Xbash" ]; then
    exec bash
fi
rsync -av /tempdata/open-c3/ /data/open-c3/
