#!/bin/bash

if command -v pip3 &> /dev/null
then
    # 华为云相关sdk
    pip3 install  huaweicloudsdkcore huaweicloudsdkdcs huaweicloudsdkecs huaweicloudsdkrds
fi

if command -v pip &> /dev/null
then
    # 阿里云相关sdk
    pip install aliyun-python-sdk-core==2.13.28 aliyun-python-sdk-ecs aliyun-python-sdk-r-kvstore aliyun-python-sdk-rds
fi