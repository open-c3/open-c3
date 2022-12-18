#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json

from aliyunsdkcore.client import AcsClient
from aliyunsdkvpc.request.v20160428.DescribeVpcAttributeRequest import DescribeVpcAttributeRequest


class Vpc:
    def __init__(self, access_id, access_key, region):
        self.region = region
        self.access_id = access_id
        self.access_key = access_key
        self.client = self.create_client()

    def create_client(self):
        client = AcsClient(self.access_id, self.access_key, self.region)
        return client
    
    def show_vpc(self, vpc_id):
        request = DescribeVpcAttributeRequest()
        request.set_accept_format('json')
        request.set_VpcId(vpc_id)
        return json.loads(self.client.do_action_with_exception(request))
