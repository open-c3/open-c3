#!/bin/bash
set -e
MODULE=$1

if [ "X$MODULE" == "X" ];then
    echo \$0 MODULE
    exit 1
fi
echo MODULE:$MODULE

VERSION=`cat $MODULE/version`;
if [ "X$VERSION" == "X" ];then
    echo nofind VERSION
    exit 1
fi

docker run --rm -v /data/open-c3:/data/open-c3 openc3/pkg-$MODULE:$VERSION
