#!/bin/bash
cd /data/open-c3/Installer/C3/pkg

VERSION=`cat open-c3-frontend/version`;
if [ "X$VERSION" == "X" ];then
    echo nofind VERSION
    exit 1
fi

docker rmi openc3/pkg-open-c3-frontend:$VERSION

./extract-module.sh  open-c3-frontend
