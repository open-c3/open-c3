#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json

from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.mongodb.v20190725 import mongodb_client, models


class MongodbInfo:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "mongodb.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return mongodb_client.MongodbClient(cred, self.region, clientProfile)

    def describe_db_instance_node_property(self, instance_id):
        req = models.DescribeDBInstanceNodePropertyRequest()
        params = {
            "InstanceId": instance_id
        }
        req.from_json_string(json.dumps(params))

        resp = self.client.DescribeDBInstanceNodeProperty(req)
        return resp
