#!/bin/bash
set -e

if [ "X$1" == "Xbash" ]; then
    exec bash
fi

cp /data/Software/mydan/perl.tar.gz /tempdata/
