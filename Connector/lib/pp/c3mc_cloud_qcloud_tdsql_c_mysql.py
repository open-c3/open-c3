#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import sys
import json

from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.cynosdb.v20190107 import cynosdb_client, models


sys.path.append("/data/Software/mydan/Connector/lib/pp")
from c3mc_utils import sleep_time_for_limiting


max_times_describe_instances = 100


class LibQcloudTdSqlCMysql:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "cynosdb.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return cynosdb_client.CynosdbClient(cred, self.region, clientProfile)

    def list_instances(self):
        """查询区域下实例列表
        """
        result = []
        req = models.DescribeInstancesRequest()
        for i in range(sys.maxsize):
            params = {
                "Limit": 100,
                "Offset": i * 100
            }
            req.from_json_string(json.dumps(params))

            resp = self.client.DescribeInstances(req)

            data_list = json.loads(resp.to_json_string())["InstanceSet"]

            if len(data_list) == 0:
                break
            result.extend(data_list)

            sleep_time_for_limiting(max_times_describe_instances)

        return result
