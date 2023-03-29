#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import sys

from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.monitor.v20180724 import monitor_client, models as monitor_models


class QcloudMonitor:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        """创建monitor sdk客户端
        """
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "monitor.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return monitor_client.MonitorClient(cred, "", clientProfile)

    def DescribeAlarmPolicies(self, project_id):
        """查询告警策略列表
        """
        result = []
        req = monitor_models.DescribeAlarmPoliciesRequest()
        for i in range(1, sys.maxsize):
            params = {
                "Module": "monitor",
                "ProjectIds": [ project_id ],
                "PageNumber": i,
                "PageSize": 50
            }
            req.from_json_string(json.dumps(params))

            resp = self.client.DescribeAlarmPolicies(req)

            policies = json.loads(resp.to_json_string())["Policies"]

            if len(policies) == 0:
                break
            result.extend(policies)
        return result
