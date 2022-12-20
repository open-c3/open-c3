#!/bin/bash

version="3.7.16"

yum install gcc make wget patch libffi-devel zlib-devel bzip2-devel openssl-devel \
    ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel xz-devel -y

cd /tmp 
wget https://www.python.org/ftp/python/${version}/Python-${version}.tar.xz
tar -xJf Python-${version}.tar.xz

cd Python-${version}
mkdir -p /usr/local/python3
./configure --prefix=/usr/local/python3 --enable-optimizations

make && make install
