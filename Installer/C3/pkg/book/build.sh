#!/bin/bash

C3BASEPATH=$( [[ "$(uname -s)" == Darwin ]] && echo "$HOME/open-c3-workspace" || echo "/data" )

set -ex

if [ -x $C3BASEPATH/open-c3-book/run ]; then
    $C3BASEPATH/open-c3-book/run
fi

cd $C3BASEPATH/open-c3/Installer/C3/pkg/book || exit

rm -rf book
git clone https://github.com/open-c3/open-c3.github.io book
bash -c "cd book; bash fix-assets.sh"
bash -c "cd book; bash fix-assets-book.sh"
tar --exclude=.git -zcf book.tar.gz book

mkdir -p _tempdata/open-c3/Connector/pkg
mv book.tar.gz _tempdata/open-c3/Connector/pkg/
mv _tempdata tempdata
