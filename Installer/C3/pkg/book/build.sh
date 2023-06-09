#!/bin/bash
set -ex

if [ -x /data/open-c3-book/run ]; then
    /data/open-c3-book/run
fi

cd /data/open-c3/Installer/C3/pkg/book || exit

rm -rf book
git clone https://github.com/open-c3/open-c3.github.io book
tar -zcf book.tar.gz book --exclude .git

mkdir -p _tempdata/open-c3/Connector/pkg
mv book.tar.gz _tempdata/open-c3/Connector/pkg/
mv _tempdata tempdata
