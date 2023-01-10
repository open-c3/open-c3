#!/bin/bash
set -e

MODULE=$1
VERSION=$2

if [ "X$MODULE" == "X" ] || [ "X$VERSION" == "X" ];then
    echo \$0 MODULE VERSION
    exit 1
fi

cd /data/open-c3/Installer/C3/pkg || exit 1

rm -rf $MODULE/tempdata
rm -rf $MODULE/_tempdata

./$MODULE/build.sh

cd $MODULE/tempdata || exit 1

git log                > git.log
git branch | grep '^*' > git.branch

tar -zcvf x.tar.gz * --exclude x.tar.gz

cp ../../entrypoint.sh .
cp ../../dockerfile    .

docker build . -t openc3/pkg-$MODULE:$VERSION --no-cache

echo $VERSION > ../version
rm -rf ../tempdata
