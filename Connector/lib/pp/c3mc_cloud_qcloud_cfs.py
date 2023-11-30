#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import sys

import json
from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.cfs.v20190719 import cfs_client, models


sys.path.append("/data/Software/mydan/Connector/lib/pp")
from c3mc_utils import sleep_time_for_limiting, bytes_to_gb

max_times_describe_file_systems = 20


class LibQcloudCfs:
    """CFS是腾讯云的文件存储服务
    """
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        """创建cfs sdk客户端
        """
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "cfs.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return cfs_client.CfsClient(cred, self.region, clientProfile)

    def describe_file_systems(self):
        """查询文件系统列表
        """
        data = []

        req = models.DescribeCfsFileSystemsRequest()
        number = 100
        for i in range(sys.maxsize):
            params = {
                "Limit": number,
                "Offset": i * number
            }
            req.from_json_string(json.dumps(params))

            resp = self.client.DescribeCfsFileSystems(req)

            file_system_list = json.loads(resp.to_json_string())["FileSystems"]

            for item in file_system_list:
                item["Region"] = self.region
                item["GBSize"] = int(bytes_to_gb(item["SizeByte"]))
                data.append(item)

            if len(file_system_list) < number:
                break

            sleep_time_for_limiting(max_times_describe_file_systems)

        return data
    