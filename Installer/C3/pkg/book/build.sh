#!/bin/bash
set -ex

cd /data/open-c3/Installer/C3/pkg/book || exit

if [ ! -d book ];then
    git clone https://github.com/open-c3/open-c3.github.io book
fi
bash -c "cd book && git pull";
tar -zcf book.tar.gz book

