#!/bin/bash
set -e

C3BASEPATH=$( [[ "$(uname -s)" == Darwin ]] && echo "$HOME/open-c3-workspace" || echo "/data" )

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

cd $C3BASEPATH/open-c3/Installer/C3/pkg || exit 1

docker push openc3/pkg-$MODULE:$VERSION

LIST_FILE="../../scripts/quick_start-image.list"
sed -i "s|openc3/pkg-$MODULE:[0-9]\+|openc3/pkg-$MODULE:$VERSION|g" "$LIST_FILE"
git add "$LIST_FILE"

git add $MODULE/version

echo "c3bot:autopkg($MODULE:$VERSION)" >> upload.txt
