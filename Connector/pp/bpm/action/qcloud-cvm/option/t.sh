#!/bin/bash

# 查询账号列表
c3mc-display-cloud-account-list qcloud
# 查询区域列表
echo '{"account": "example-account"}' | c3mc-qcloud-cvm-describe-regions
# 查询可用区列表
echo '{"account": "example-account", "region": "ap-beijing"}' | c3mc-qcloud-cvm-describe-zones
# 查询项目列表
echo '{"account": "example-account", "region": "ap-beijing"}' | c3mc-qcloud-cvm-describe-projects
# 查询机型列表
echo '{"account": "example-account", "region": "ap-beijing", "zone": "ap-beijing-2", "charge_type": "PREPAID"}' | c3mc-qcloud-cvm-describe-instance-configs
# 查询镜像列表
echo '{"account": "example-account", "region": "ap-beijing"}' | c3mc-qcloud-cvm-describe-images
# 查询vpc列表
echo '{"account": "example-account", "region": "ap-beijing"}' | c3mc-qcloud-cvm-describe-vpcs
# 查询子网列表
echo '{"account": "example-account", "region": "ap-beijing", "vpc_id": "vpc-cvjoiwf"}' | c3mc-qcloud-cvm-describe-subnets
# 查询安全组列表
echo '{"account": "example-account", "region": "ap-beijing", "project_id": 10212324}' | c3mc-qcloud-cvm-describe-security-groups
# 查询自动续费标识列表
c3mc-qcloud-cvm-describe-renew-flag-list
