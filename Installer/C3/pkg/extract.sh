#!/bin/bash
set -e

VERSION=2212191
if [ "X$1" != "X" ];then
    VERSION=$1
fi
echo VERSION:$VERSION

docker run -v /data/open-c3:/data/open-c3 openc3/pkg:$VERSION
