#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import urllib.request
import json


def get_price_file():
    """
        获取aws中国区rds的价格文件。

        本来可以通过boto3的pricing服务获取价格信息, 但是目前中国区调用
        这个服务会报错, 咨询aws工程师后, 给的建议是从下面地址获取价格文件
    """
    url = 'https://pricing.amazonaws.com/offers/v1.0/cn/AmazonRDS/current/cn-northwest-1/index.json'

    with urllib.request.urlopen(url) as url:
        return json.load(url)
