#!/bin/bash

commitid=$1

if [ "X$commitid" == "X" ];then
    echo ./$0 commitid
    exit 1
fi

BASE_PATH=/data/open-c3

cd $BASE_PATH/tools/bf || exit 1

rm -rf open-c3
git clone   git@github.com:open-c3/open-c3.git 

bash -c "cd open-c3 && git reset --hard  $commitid"

rsync -av $BASE_PATH/Installer/dev-cache/c3-front/ $BASE_PATH/tools/bf/open-c3/c3-front/

docker run --rm -i -v /data/open-c3/tools/bf/open-c3/c3-front/:/code openc3/gulp bower install --allow-root
docker run --rm -i -v /data/open-c3/tools/bf/open-c3/c3-front/:/code openc3/gulp gulp build
        
rsync -av /data/open-c3/tools/bf/open-c3/c3-front/dist/ /data/open-c3/c3-front/dist/ --delete

rm -rf open-c3
