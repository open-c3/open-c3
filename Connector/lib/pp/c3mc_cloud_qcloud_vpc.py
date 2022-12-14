#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json

from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.vpc.v20170312 import vpc_client, models


class Vpc:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "vpc.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return vpc_client.VpcClient(cred, self.region, clientProfile)

    def show_vpc(self, vpc_id):
        req = models.DescribeVpcsRequest()
        params = {
            "VpcIds": [ vpc_id ]
        }
        req.from_json_string(json.dumps(params))
        resp = self.client.DescribeVpcs(req)
        return json.loads(resp.to_json_string())["VpcSet"][0]

