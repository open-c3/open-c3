#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json

from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.dcdb.v20180411 import dcdb_client, models


class Project:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "dcdb.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return dcdb_client.DcdbClient(cred, self.region, clientProfile)

    def show_projects(self):
        req = models.DescribeProjectsRequest()
        params = {}
        req.from_json_string(json.dumps(params))
        resp = self.client.DescribeProjects(req)
        return json.loads(resp.to_json_string())["Projects"]
