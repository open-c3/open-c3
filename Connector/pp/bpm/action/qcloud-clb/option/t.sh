#!/bin/bash

# 查询账号列表
c3mc-display-cloud-account-list qcloud
# 查询区域列表
echo '{"account": "openc3test"}' | c3mc-qcloud-cvm-describe-regions | c3mc-bpm-display-field-values Region,RegionName,RegionState
# 实例类型
c3mc-qcloud-clb-describe-instance-type-list | c3mc-bpm-display-field-values id,name
# 网络类型
c3mc-qcloud-clb-describe-network-type-list | c3mc-bpm-display-field-values id,name
# 查询项目列表
echo '{"account": "openc3test", "region": "ap-beijing"}' | c3mc-qcloud-cvm-describe-projects | c3mc-bpm-display-field-values ProjectId,Name
# 协议类型
c3mc-qcloud-clb-describe-protocol-type-list | c3mc-bpm-display-field-values id,name
# 负载均衡方式列表
c3mc-qcloud-clb-describe-balancer-type-list | c3mc-bpm-display-field-values id,name
# 查询cvm列表
echo '{"account": "openc3test", "region": "ap-beijing"}' | c3mc-qcloud-clb-describe-cvm-list | c3mc-bpm-display-field-values InstanceId,InstanceName,PrivateIp,PublicIp
