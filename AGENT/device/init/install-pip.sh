#!/bin/bash

set -e

cd /tmp
wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
python ./get-pip.py

ln -fsn /usr/local/python3/bin/pip3.7 /usr/local/bin/pip3

rm -rf /tmp/get-pip.py
