#!/bin/bash

version="3.7.16"

yum install gcc make wget patch libffi-devel zlib-devel bzip2-devel openssl-devel \
    ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel xz-devel -y

cd /tmp 
wget https://www.python.org/ftp/python/${version}/Python-${version}.tar.xz
tar -xJf Python-${version}.tar.xz

cd Python-${version}
mkdir -p /data/Software/mydan/python3
./configure --prefix=/data/Software/mydan/python3
#./configure --prefix=/data/Software/mydan/python3 --enable-optimizations
# C3TODO 240305 ubuntu系统编译python不支持 --enable-optimizations 参数
# 添加这个参数的情况下，编辑过程会卡住

make -j6 && make install
