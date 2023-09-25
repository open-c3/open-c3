#!/bin/bash

rm -rf dist
./dev.sh build

DIR=/data/open-c3/Installer/C3/pkg/install-cache/install-cache/trouble-ticketing/tt-front

if [ ! -d $DIR ]; then
    exit
fi

if [ -d "$DIR/dist" ]; then
    bash -c "cd $DIR && git rm -rf dist"
fi

cp -r dist $DIR/
bash -c "cd $DIR && git add dist"

echo "到 $DIR 路径下提交代码"
echo "添加一些数据到 /data/open-c3/Installer/C3/pkg/install-cache/README.md, 然后提交代码"
