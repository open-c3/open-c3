#!/bin/bash

#需要python 2.7.18 或 以上版本
python2 -V
if [ $? == 0 ]; then
    V1=$(python -V 2>&1|awk '{print $2}'|awk -F. '{print $1}')
    V2=$(python -V 2>&1|awk '{print $2}'|awk -F. '{print $2}')
    V3=$(python -V 2>&1|awk '{print $2}'|awk -F. '{print $3}')

    if [[ $V1 -ge 2 && $V2 -ge 7 && $V3 -ge 18 ]] ;then
        exit
    fi
fi

yum install gcc patch libffi-devel python-devel zlib-devel bzip2-devel openssl-devel \
    ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel -y

yum install wget -y

cd /tmp 
wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz
tar -zxvf Python-2.7.18.tgz

cd Python-2.7.18
./configure --enable-optimizations

make && make install


rm -f /usr/bin/python
ln -s /usr/local/bin/python2.7 /usr/bin/python

cd /tmp
wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
python ./get-pip.py

rm -rf /tmp/Python-2.7.18* get-pip.py
