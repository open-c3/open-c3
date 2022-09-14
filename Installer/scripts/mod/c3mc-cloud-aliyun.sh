#!/bin/bash

if command -v pip &> /dev/null
then
    pip install aliyun-python-sdk-core==2.13.28 aliyun-python-sdk-ecs aliyun-python-sdk-r-kvstore aliyun-python-sdk-rds
fi