#!/bin/bash

# 查询账号列表
c3mc-display-cloud-account-list qcloud
# 查询区域列表
echo '{"account": "example-account"}' | c3mc-qcloud-cvm-describe-regions | c3mc-bpm-display-field-values Region,RegionName,RegionState
# 查询可用区列表
echo '{"account": "example-account", "region": "ap-beijing"}' | c3mc-qcloud-cvm-describe-zones | c3mc-bpm-display-field-values Zone,ZoneName,ZoneState
# 查询项目列表
echo '{"account": "example-account", "region": "ap-beijing"}' | c3mc-qcloud-cvm-describe-projects | c3mc-bpm-display-field-values ProjectId,Name
# 查询机型列表
echo '{"account": "example-account", "region": "ap-beijing", "zone": "ap-beijing-2", "charge_type": "PREPAID"}' | c3mc-qcloud-cvm-describe-instance-configs | c3mc-bpm-display-field-values InstanceType,Cpu,Memory,Status,Gpu
# 查询镜像列表
echo '{"account": "example-account", "region": "ap-beijing"}' | c3mc-qcloud-cvm-describe-images | c3mc-bpm-display-field-values ImageId,ImageName
# 查询系统盘类型列表
c3mc-qcloud-cvm-describe-system-disk-type-list | c3mc-bpm-display-field-values id,name,size_range
# 是否需要数据盘
c3mc-yes-and-no | c3mc-bpm-display-field-values id,name
# 查询数据盘类型列表
c3mc-qcloud-cvm-describe-data-disk-type-list | c3mc-bpm-display-field-values id,name,size_range
# 查询vpc列表
echo '{"account": "example-account", "region": "ap-beijing"}' | c3mc-qcloud-cvm-describe-vpcs | c3mc-bpm-display-field-values VpcId,VpcName
# 查询子网列表
echo '{"account": "example-account", "region": "ap-beijing", "vpc_id": "vpc-wefwefwef", "zone": "ap-beijing-4"}' | c3mc-qcloud-cvm-describe-subnets | c3mc-bpm-display-field-values SubnetId,SubnetName,AvailableIpAddressCount
# 查询安全组列表
echo '{"account": "example-account", "region": "ap-beijing", "project_id": 1234434}' | c3mc-qcloud-cvm-describe-security-groups | c3mc-bpm-display-field-values SecurityGroupId,SecurityGroupName
