#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json

from aliyunsdkcore.client import AcsClient
from aliyunsdkrds.request.v20140815.DescribeDBInstanceByTagsRequest import DescribeDBInstanceByTagsRequest


class GetTag:
    def __init__(self, access_id, access_key, region, instance_id):
        self.region = region
        self.access_id = access_id
        self.access_key = access_key
        self.instance_id = instance_id
        self.client = self.create_client()

    def create_client(self):
        client = AcsClient(self.access_id, self.access_key, self.region)
        return client

    def set_desc_tag_request(self):
        request = DescribeDBInstanceByTagsRequest()
        request.set_accept_format('json')
        request.set_DBInstanceId(self.instance_id)
        return request

    def get_desc_tag_response(self):
        request = self.set_desc_tag_request()
        response = self.client.do_action_with_exception(request)
        response_data = json.loads(response)
        return response_data

    def list_tag(self):
        tag_response = self.get_desc_tag_response()
        if len(tag_response["Items"]["DBInstanceTag"]) > 0:
            return tag_response["Items"]["DBInstanceTag"][0]["Tags"]["Tag"]
        return []
