#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.common.exception.tencent_cloud_sdk_exception import TencentCloudSDKException
from tencentcloud.cvm.v20170312 import cvm_client, models


class Cvm:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "cvm.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return cvm_client.CvmClient(cred, self.region, clientProfile)

    def show_cvm(self, instance_id):
        req = models.DescribeInstancesRequest()
        params = {
            "InstanceIds": [ instance_id ]
        }
        req.from_json_string(json.dumps(params))
        resp = self.client.DescribeInstances(req)
        return json.loads(resp.to_json_string())["InstanceSet"][0]
