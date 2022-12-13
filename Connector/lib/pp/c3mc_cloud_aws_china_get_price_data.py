#!/usr/bin/env python3
# -*- coding: utf-8 -*-


from c3mc_cloud_aws_china_price import get_price, get_instance_type_info_m, get_instance_types

def get_ec2_url(region):
    return "https://pricing.amazonaws.com/offers/v1.0/cn/AmazonEC2/current/{}/index.json".format(region)

def get_rds_url(region):
    return "https://pricing.amazonaws.com/offers/v1.0/cn/AmazonRDS/current/{}/index.json".format(region)

def get_elasticache_url(region):
    return "https://pricing.amazonaws.com/offers/v1.0/cn/AmazonElastiCache/current/{}/index.json".format(region)


def get_ec2_price(region, instance_type):
    url = get_ec2_url(region)
    filepath = "/tmp/aws_ec2/{}/index.json".format(region)
    return get_price(
        [
            {"instanceType": instance_type}, 
            {"tenancy": "Shared"}, 
            {"operatingSystem": "Linux"}, 
            {"preInstalledSw": "NA"}
        ], 
        ["instancesku"],
        filepath, 
        url
    )

def get_rds_price(region, instance_type):
    url = get_rds_url(region)
    filepath = "/tmp/aws_rds/{}/index.json".format(region)
    return get_price(
        [{"instanceType": instance_type}], 
        [],
        filepath, 
        url
    )

def get_elasticache_price(region, instance_type):
    url = get_elasticache_url(region)
    filepath = "/tmp/aws_elasticache/{}/index.json".format(region)
    return get_price(
        [{"instanceType": instance_type}], 
        [],
        filepath, 
        url
    )

def get_ebs_price(region, volume_api_name, volume_type):
    url = get_ec2_url(region)
    filepath = "/tmp/aws_ec2/{}/index.json".format(region)
    return get_price(
        [{"volumeApiName": volume_api_name}, {"volumeType": volume_type}], 
        [],
        filepath, 
        url
    )


def get_ec2_instance_type_info_m(region):
    url = get_ec2_url(region)
    filepath = "/tmp/aws_ec2/{}/index.json".format(region)
    return get_instance_type_info_m(filepath, url)

def get_rds_instance_type_info_m(region):
    url = get_rds_url(region)
    filepath = "/tmp/aws_rds/{}/index.json".format(region)
    return get_instance_type_info_m(filepath, url)

def get_elasticache_instance_type_info_m(region):
    url = get_elasticache_url(region)
    filepath = "/tmp/aws_elasticache/{}/index.json".format(region)
    return get_instance_type_info_m(filepath, url)


def get_ec2_instance_types(region):
    url = get_ec2_url(region)
    filepath = "/tmp/aws_ec2/{}/index.json".format(region)
    return get_instance_types(
        [
            {"tenancy": "Shared"}, 
            {"operatingSystem": "Linux"}, 
            {"preInstalledSw": "NA"}
        ], 
        ["instancesku"],
        filepath, 
        url,
        ["instanceType", "vcpu", "memory"]
    )