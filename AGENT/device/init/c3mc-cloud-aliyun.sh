#!/bin/bash

set -e

pip3.7 install pycrypto -U
pip3.7 install pycryptodome -U

pip3.7 install aliyun-python-sdk-core aliyunsdkcore aliyun-python-sdk-ecs \
      aliyun-python-sdk-r-kvstore aliyun-python-sdk-rds aliyun-python-sdk-slb oss2