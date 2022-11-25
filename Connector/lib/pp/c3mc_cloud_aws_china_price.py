#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import json
from c3mc_utils import redownload_file_if_need


def get_price_file_data(filepath, url):
    """
        获取aws中国区资源的价格文件。

        本来可以通过boto3的pricing服务获取价格信息, 但是目前中国区调用
        这个服务会报错, 咨询aws工程师后, 给的建议是从指定地址获取价格文件
    """
    alive_seconds = 24 * 60 * 60
    redownload_file_if_need(filepath, url, alive_seconds)

    data = {}
    with open(filepath) as json_file:
        data = json.load(json_file)
    return data


def get_instance_type_info_m(filepath, url):
    data = get_price_file_data(filepath, url)
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
    

def get_price(instance_type, filepath, url):
    """
        返回指定实例类型在指定区域(filepath已经指定价格文件地址)按需的小时价格
    """
    data = get_price_file_data(filepath, url)

    target_code = None
    for code in data["products"]:
        attr = data["products"][code]["attributes"]
        if "instanceType" not in attr:
            continue
        if attr["instanceType"] == instance_type:
                target_code = code
                break

    od = data['terms']['OnDemand']
    od = od[target_code][list(od[target_code])[0]]["priceDimensions"]
    od = od[list(od)[0]]["pricePerUnit"]
    return  {
        "amount": od[list(od)[0]],
        "money_type": list(od)[0],
    }