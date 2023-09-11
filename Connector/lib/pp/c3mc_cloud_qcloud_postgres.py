#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import time
import sys
import subprocess

import json
from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.common.exception.tencent_cloud_sdk_exception import TencentCloudSDKException
from tencentcloud.postgres.v20170312 import postgres_client, models


sys.path.append("/data/Software/mydan/Connector/lib/pp")
from c3mc_utils import sleep_time_for_limiting

max_times_db_instances = 1000


class LibQcloudPostgres:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        """postgres sdk客户端
        """
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "postgres.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return postgres_client.PostgresClient(cred, self.region, clientProfile)

    def describe_db_instances(self):
        """查询实例列表
        """
        result = []

        req = models.DescribeDBInstancesRequest()
        for i in range(sys.maxsize):
            params = {
                "Limit": 100,
                "Offset": i * 100
            }
            req.from_json_string(json.dumps(params))

            resp = self.client.DescribeDBInstances(req)

            sleep_time_for_limiting(max_times_db_instances)

            backup_list = json.loads(resp.to_json_string())["DBInstanceSet"]

            if len(backup_list) == 0:
                break
            result.extend(backup_list)
        return result
