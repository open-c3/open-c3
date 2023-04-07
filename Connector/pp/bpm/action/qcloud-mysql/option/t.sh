#!/bin/bash

# 区域
echo '{"account": "opencetest"}' | c3mc-bpm-option-qcloud-mysql-describe-regions | c3mc-bpm-display-field-values id,name


# 主可用区
echo '{"account": "opencetest", "region": "ap-beijing"}' | c3mc-bpm-option-qcloud-mysql-describe-zones | c3mc-bpm-display-field-values zone,zone_name,status


# 售卖实例类型
echo '{"account": "opencetest", "region": "ap-beijing", "zone": "ap-beijing-1", "charge_type": "按量计费"}' | c3mc-bpm-option-qcloud-mysql-describe-cdb-sell-type-list | c3mc-bpm-display-field-values id,desc


# 数据库版本
echo '{"account": "opencetest", "region": "ap-beijing", "zone": "ap-beijing-1", "charge_type": "按量计费", "cdb_sell_type": "Z3"}' | c3mc-bpm-option-qcloud-mysql-describe-engine-version-list | c3mc-bpm-display-field-values id,name


# 引擎类型
echo '{"account": "opencetest", "region": "ap-beijing", "zone": "ap-beijing-1", "charge_type": "按量计费", "cdb_sell_type": "Z3"}' | c3mc-bpm-option-qcloud-mysql-describe-engine-type-list | c3mc-bpm-display-field-values id,name


# 架构
echo '{"engine_type": "RocksDB"}' | c3mc-bpm-option-qcloud-mysql-describe-instance-nodes-set | c3mc-bpm-display-field-values id,name


# 备可用区1
echo '{"account": "opencetest", "region": "ap-beijing", "zone": "ap-beijing-1", "charge_type": "包年包月"}' | c3mc-bpm-option-qcloud-mysql-describe-backup-zones | c3mc-bpm-display-field-values id,name


# 实例配置
echo '{"account": "opencetest", "region": "ap-beijing", "zone": "ap-beijing-3", "charge_type": "按量计费", "cdb_sell_type": "Z3", "device_type": "UNIVERSAL", "engine_type": "InnoDB"}' | c3mc-bpm-option-qcloud-mysql-describe-instance-config-list | c3mc-bpm-display-field-values c3mc-bpm-display-field-values "{Id};Cpu:{Cpu}核, 内存:{Memory}MB, IOPS:{Iops}, 最小磁盘:{VolumeMin}GB, 最大磁盘: {VolumeMax}GB"


# vpc
echo '{"account": "opencetest", "region": "ap-beijing"}' | c3mc-qcloud-cvm-describe-vpcs | c3mc-bpm-display-field-values VpcId,VpcName

# 子网
echo '{"account": "opencetest", "region": "ap-beijing", "vpc_id": "vpc-xxxxxx", "zone": "ap-beijing-1"}' | c3mc-qcloud-cvm-describe-subnets | c3mc-bpm-display-field-values SubnetId,SubnetName,AvailableIpAddressCount


# 项目
echo '{"account": "opencetest", "region": "ap-beijing"}' | c3mc-qcloud-cvm-describe-projects | c3mc-bpm-display-field-values ProjectId,Name

# 安全组
echo '{"account": "opencetest", "region": "ap-beijing", "project_id": 1176222121}' | c3mc-qcloud-cvm-describe-security-groups | c3mc-bpm-display-field-values SecurityGroupId,SecurityGroupName


# 告警策略
echo '{"account": "opencetest", "region": "ap-beijing", "project_id": 1172121313}' | c3mc-bpm-option-qcloud-mysql-describe-alarm-policies-list | c3mc-bpm-display-field-values PolicyId,PolicyName,NamespaceShowName


# 参数模板
echo '{"account": "opencetest", "engine_type": "InnoDB", "engine_version": "8.0"}' | c3mc-bpm-option-qcloud-mysql-describe-param-templates | c3mc-bpm-display-field-values TemplateId,Name,TemplateType,Description


# 字符集排序规则
echo '{"charset_type": "UTF8"}' | c3mc-bpm-option-qcloud-mysql-describe-available-collation | c3mc-bpm-display-field-values id,name


# 查询默认的可设置参数列表
echo '{"account": "opencetest", "engine_type": "InnoDB", "engine_version": "8.0"}' | c3mc-bpm-option-qcloud-mysql-describe-describe-default-params
