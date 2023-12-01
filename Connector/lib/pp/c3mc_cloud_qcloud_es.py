#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import sys

import json
from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.es.v20180416 import es_client, models


sys.path.append("/data/Software/mydan/Connector/lib/pp")
from c3mc_utils import sleep_time_for_limiting

max_times_describe_es = 20


class LibQcloudES:
    """ES是腾讯云的 Elasticsearch Service
    """
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        """创建es sdk客户端
        """
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "es.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return es_client.EsClient(cred, self.region, clientProfile)

    def describe_instances(self):
        """查询es实例列表
        """
        status_text = {
            0: "处理中",
            1: "正常",
            2: "创建集群时初始化中",
            -1: "停止",
            -2: "销毁中",
            -3: "已销毁"
        }
        result = []

        req = models.DescribeInstancesRequest()
        number = 100
        for i in range(sys.maxsize):
            params = {
                "Limit": number,
                "Offset": i * number
            }
            req.from_json_string(json.dumps(params))

            resp = self.client.DescribeInstances(req)

            instance_list = json.loads(resp.to_json_string())["InstanceList"]

            for item in instance_list:
                item["StatusText"] = status_text[int(item["Status"])]
                del item["Status"]
                result.append(item)

            if len(instance_list) < number:
                break

            sleep_time_for_limiting(max_times_describe_es)

        return result
    