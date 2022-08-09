#!/bin/bash
set -e
curl https://bootstrap.pypa.io/pip/2.7/get-pip.py  > get-pip.py 
python get-pip.py 
pip install aliyun-python-sdk-core
pip install aliyun-python-sdk-ecs
