#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json

from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkvpc.v3.region.vpc_region import VpcRegion
from huaweicloudsdkvpc.v3 import *


class HuaweiVpc:
    def __init__(self, access_id, access_key, project_id, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        if project_id == None:
            self.project_id = None
        else:
            self.project_id = project_id.strip()
        self.client = self.create_client()

    def create_client(self):
        credentials = BasicCredentials(self.access_id, self.access_key, self.project_id)

        return VpcClient.new_builder() \
            .with_credentials(credentials) \
            .with_region(VpcRegion.value_of(self.region)) \
            .build()

    def show_vpc(self, vpc_id):
        request = ShowVpcRequest()
        request.vpc_id = vpc_id
        response = self.client.show_vpc(request)
        return json.loads(str(response))["vpc"]
