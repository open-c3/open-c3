#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import time
import sys

import json
from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.cbs.v20170312 import cbs_client, models


sys.path.append("/data/Software/mydan/Connector/lib/pp")
from c3mc_utils import sleep_time_for_limiting

max_times_describe_disks = 100


class LibQcloudCbs:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        """创建cbs sdk客户端
        """
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "cbs.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return cbs_client.CbsClient(cred, self.region, clientProfile)

    def describe_disks_for_ids(self, disk_ids):
        """查询云硬盘列表

        Args:
            disk_ids (list): 指定的云硬盘id列表
        """
        data = []

        req = models.DescribeDisksRequest()
        for i in range(sys.maxsize):
            params = {
                "DiskIds": disk_ids,
                "Limit": 100,
                "Offset": i * 100
            }
            req.from_json_string(json.dumps(params))

            resp = self.client.DescribeDisks(req)

            disk_list = json.loads(resp.to_json_string())["DiskSet"]

            if len(disk_list) == 0:
                break
            data.extend(disk_list)

            sleep_time_for_limiting(max_times_describe_disks)

        return data
    