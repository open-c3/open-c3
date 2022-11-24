#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import json
from c3mc_utils import redownload_file_if_need

def get_price_file_data():
    """
        获取aws中国区rds的价格文件。

        本来可以通过boto3的pricing服务获取价格信息, 但是目前中国区调用
        这个服务会报错, 咨询aws工程师后, 给的建议是从下面地址获取价格文件
    """
    
    filepath = "/tmp/aws_rds/index.json"
    alive_seconds = 24 * 60 * 60
    url = 'https://pricing.amazonaws.com/offers/v1.0/cn/AmazonRDS/current/cn-northwest-1/index.json'

    redownload_file_if_need(filepath, url, alive_seconds)

    data = {}
    with open(filepath) as json_file:
        data = json.load(json_file)
    return data


def get_instance_type_info_m():
    """
        返回数据的格式如下:
            {
                "cn-northwest-1":
                {
                    "db.r4.xlarge":
                    {
                        "Multi-AZ":
                        {
                            "servicecode": "AmazonRDS",
                            "location": "China (Ningxia)",
                            "locationType": "AWS Region",
                            "instanceType": "db.r4.xlarge",
                            "currentGeneration": "No",
                            "instanceFamily": "Memory optimized",
                            "vcpu": "4",
                            "physicalProcessor": "Intel Xeon E5-2686 v4 (Broadwell)",
                            "clockSpeed": "2.3 GHz",
                            "memory": "30.5 GiB",
                            "storage": "EBS Only",
                            "networkPerformance": "Up to 10 Gigabit",
                            "processorArchitecture": "64-bit",
                            "engineCode": "2",
                            "databaseEngine": "MySQL",
                            "licenseModel": "No license required",
                            "deploymentOption": "Multi-AZ",
                            "usagetype": "CNW1-Multi-AZUsage:db.r4.xlarge",
                            "operation": "CreateDBInstance:0002",
                            "dedicatedEbsThroughput": "800 Mbps",
                            "enhancedNetworkingSupported": "Yes",
                            "instanceTypeFamily": "R4",
                            "normalizationSizeFactor": "16",
                            "processorFeatures": "Intel AVX, Intel AVX2, Intel Turbo",
                            "regionCode": "cn-northwest-1",
                            "servicename": "Amazon Relational Database Service"
                        },
                        "Single-AZ":
                        {
                            "servicecode": "AmazonRDS",
                            "location": "China (Ningxia)",
                            "locationType": "AWS Region",
                            "instanceType": "db.r4.xlarge",
                            "currentGeneration": "No",
                            "instanceFamily": "Memory optimized",
                            "vcpu": "4",
                            "physicalProcessor": "Intel Xeon E5-2686 v4 (Broadwell)",
                            "clockSpeed": "2.3 GHz",
                            "memory": "30.5 GiB",
                            "storage": "EBS Only",
                            "networkPerformance": "Up to 10 Gigabit",
                            "processorArchitecture": "64-bit",
                            "engineCode": "20",
                            "databaseEngine": "Oracle",
                            "databaseEdition": "Standard Two",
                            "licenseModel": "License included",
                            "deploymentOption": "Single-AZ",
                            "usagetype": "CNW1-InstanceUsage:db.r4.xlarge",
                            "operation": "CreateDBInstance:0020",
                            "dedicatedEbsThroughput": "800 Mbps",
                            "enhancedNetworkingSupported": "Yes",
                            "instanceTypeFamily": "R4",
                            "normalizationSizeFactor": "NA",
                            "processorFeatures": "Intel AVX, Intel AVX2, Intel Turbo",
                            "regionCode": "cn-northwest-1",
                            "servicename": "Amazon Relational Database Service"
                        }
                    },
                    ....
                }
            }
    """
    data = get_price_file_data()
    attr_m = {}
    for code in data["products"]:
        attr = data["products"][code]["attributes"]
        if "instanceType" not in attr:
            continue
        if attr["regionCode"] not in attr_m:
            attr_m[attr["regionCode"]] = {}
        if attr["instanceType"] not in attr_m[attr["regionCode"]]:
            attr_m[attr["regionCode"]][attr["instanceType"]] = {}
        # 对于相同的regionCode、instanceType、deploymentOption, attr可能会有多个，主要区别是数据库种类不一样
        # 但是cpu、memory等主要信息是一致的，如果不在乎数据库种类，使用该方法没有问题
        attr_m[attr["regionCode"]][attr["instanceType"]][attr["deploymentOption"]] = attr
    return attr_m