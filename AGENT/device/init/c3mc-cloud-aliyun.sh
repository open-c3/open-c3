#!/bin/bash

set -e

pip3 install pycrypto -U
pip3 install pycryptodome -U

pip3 install aliyun-python-sdk-core aliyunsdkcore aliyun-python-sdk-ecs \
      aliyun-python-sdk-r-kvstore aliyun-python-sdk-rds aliyun-python-sdk-slb oss2