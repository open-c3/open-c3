#!/bin/bash

VERSION=$1
if [ "X$VERSION" == "X" ];then
    VERSION=$(date +%Y%m%d)
fi
echo VERSION:$VERSION
time docker build . -t openc3/basev2:$VERSION -f dockerfile . --no-cache
