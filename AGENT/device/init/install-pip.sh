#!/bin/bash

set -e

cd /tmp
wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
python ./get-pip.py

rm -rf /tmp/get-pip.py
