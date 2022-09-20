#!/bin/bash


yum install gcc patch libffi-devel python-devel zlib-devel bzip2-devel openssl-devel \
    ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel -y

yum install wget -y

cd /tmp 
wget https://www.python.org/ftp/python/3.7.10/Python-3.7.10.tgz
tar -zxvf Python-3.7.10.tgz

cd Python-3.7.10
mkdir -p /usr/local/python3
./configure --prefix=/usr/local/python3 --enable-optimizations

make && make install

ln -s /usr/local/python3/bin/python3.7 /usr/bin/python3
ln -s /usr/local/python3/bin/pip3.7 /usr/local/bin/pip3

rm -rf /tmp/Python-3.7.10
