#!/bin/bash
set -ex

VERSION=$1
if [ "X$VERSION" == "X" ];then
    VERSION=$(date +%y%m%d)
fi
echo VERSION:$VERSION

cd /data/open-c3/Installer/C3/pkg || exit

rm -rf tempdata
mkdir  tempdata

mkdir -p tempdata/open-c3/Connector/pkg
# perl
./perl/build.sh
cp perl/perl.tar.gz tempdata/open-c3/Connector/pkg/perl.tar.gz

# install-cache
./install-cache/build.sh
cp install-cache/install-cache.tar.gz tempdata/open-c3/Connector/pkg/install-cache.tar.gz

# dev-cache
./dev-cache/build.sh
cp dev-cache/dev-cache.tar.gz tempdata/open-c3/Connector/pkg/dev-cache.tar.gz

# book
./book/build.sh
cp book/book.tar.gz tempdata/open-c3/Connector/pkg/book.tar.gz

# trouble-ticketing
bash -c "cd /data/open-c3/Connector/tt/trouble-ticketing && ./build.sh"
cp /data/open-c3/Connector/tt/trouble-ticketing/trouble-ticketing tempdata/open-c3/Connector/pkg/
chmod +x tempdata/open-c3/Connector/pkg/trouble-ticketing

#jumpserver
bash -c "cd /data/open-c3/Connector/bl/sync/jumpserver && ./build.sh"
mkdir -p tempdata/open-c3/Connector/bl/sync/jumpserver
cp /data/open-c3/Connector/bl/sync/jumpserver/jumpserver tempdata/open-c3/Connector/bl/sync/jumpserver/
chmod +x tempdata/open-c3/Connector/bl/sync/jumpserver/jumpserver

# baseinfo
git log                > tempdata/git.log
git branch | grep '^*' > tempdata/git.branch

docker build . -t openc3/pkg:$VERSION --no-cache
