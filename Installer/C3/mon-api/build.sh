#!/bin/bash

VERSION=$1
if [ "X$VERSION" == "X" ];then
    VERSION=$(date +%Y%m%d)
fi
echo VERSION:$VERSION

cp ../c3-api/dockerfile .
cp ../c3-api/nginx.conf .

time docker build . -t openc3/mon-api:$VERSION -f dockerfile --no-cache

rm dockerfile nginx.conf
