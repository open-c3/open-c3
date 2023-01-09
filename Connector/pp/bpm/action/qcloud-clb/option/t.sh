#!/bin/bash

# 查询账号列表
c3mc-display-cloud-account-list qcloud
# 查询区域列表
echo '{"account": "openc3test"}' | c3mc-qcloud-cvm-describe-regions | c3mc-bpm-display-field-values Region,RegionName,RegionState
# 查询项目列表
echo '{"account": "openc3test", "region": "ap-beijing"}' | c3mc-qcloud-cvm-describe-projects | c3mc-bpm-display-field-values ProjectId,Name
# 查询cvm列表
echo '{"account": "openc3test", "region": "ap-beijing"}' | c3mc-qcloud-clb-describe-cvm-list | c3mc-bpm-display-field-values InstanceId,InstanceName,PrivateIp,PublicIp
