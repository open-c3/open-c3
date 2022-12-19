#!/bin/bash
set -ex

VERSION=$1
if [ "X$VERSION" == "X" ];then
    VERSION=$(date +%y%m%d)
fi
echo VERSION:$VERSION
MODULE=$2

cd /data/open-c3/Installer/C3/pkg || exit

rm -rf tempdata
mkdir  tempdata

mkdir -p tempdata/open-c3/Connector/pkg
# perl
if [ "X$MODULE" == "X" ] || [ "X$MODULE" == "Xperl" ] ;then
    ./perl/build.sh
    cp perl/perl.tar.gz tempdata/open-c3/Connector/pkg/perl.tar.gz
fi

# install-cache
if [ "X$MODULE" == "X" ] || [ "X$MODULE" == "install-cache" ];then
    ./install-cache/build.sh
    cp install-cache/install-cache.tar.gz tempdata/open-c3/Connector/pkg/install-cache.tar.gz
fi

# dev-cache
if [ "X$MODULE" == "X" ] || [ "X$MODULE" == "Xdev-cache" ];then
    ./dev-cache/build.sh
    cp dev-cache/dev-cache.tar.gz tempdata/open-c3/Connector/pkg/dev-cache.tar.gz
fi

# book
if [ "X$MODULE" == "X" ] || [ "X$MODULE" == "Xbook" ];then
    ./book/build.sh
    cp book/book.tar.gz tempdata/open-c3/Connector/pkg/book.tar.gz
fi

# trouble-ticketing
if [ "X$MODULE" == "X" ] || [ "X$MODULE" == "Xtrouble-ticketing" ];then
    bash -c "cd /data/open-c3/Connector/tt/trouble-ticketing && ./build.sh"
    cp /data/open-c3/Connector/tt/trouble-ticketing/trouble-ticketing tempdata/open-c3/Connector/pkg/
    chmod +x tempdata/open-c3/Connector/pkg/trouble-ticketing
fi

#jumpserver
if [ "X$MODULE" == "X" ] || [ "X$MODULE" == "Xjumpserver" ];then
    bash -c "cd /data/open-c3/Connector/bl/sync/jumpserver && ./build.sh"
    mkdir -p tempdata/open-c3/Connector/bl/sync/jumpserver
    cp /data/open-c3/Connector/bl/sync/jumpserver/jumpserver tempdata/open-c3/Connector/bl/sync/jumpserver/
    chmod +x tempdata/open-c3/Connector/bl/sync/jumpserver/jumpserver
fi

# baseinfo
if [ "X$MODULE" == "X" ];then
    git log                > tempdata/git.log
    git branch | grep '^*' > tempdata/git.branch
    docker build . -t openc3/pkg:$VERSION --no-cache
else

    TIME=$(date +%Y%m%d%H%M%S)
    mkdir tempdata/$TIME
    echo $MODULE           > tempdata/$TIME/patch.log
    git log                > tempdata/$TIME/git.log
    git branch | grep '^*' > tempdata/$TIME/git.branch
    docker build . -t openc3/pkg:$VERSION --no-cache -f dockerfile_patch
fi

