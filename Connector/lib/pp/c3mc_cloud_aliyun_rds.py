#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json

from aliyunsdkcore.client import AcsClient
from aliyunsdkrds.request.v20140815.TagResourcesRequest import TagResourcesRequest
from aliyunsdkrds.request.v20140815.RemoveTagsFromResourceRequest import RemoveTagsFromResourceRequest
from aliyunsdkrds.request.v20140815.DescribeDBInstanceByTagsRequest import DescribeDBInstanceByTagsRequest
from aliyunsdkrds.request.v20140815.DescribeRegionsRequest import DescribeRegionsRequest



class LibAliyunRds:
    def __init__(self, access_id, access_key, region):
        self.region = region
        self.access_id = access_id
        self.access_key = access_key
        self.client = self.create_client()

    def create_client(self):
        return AcsClient(self.access_id, self.access_key, self.region)

    def list_tag(self, instance_id):
        request = DescribeDBInstanceByTagsRequest()
        request.set_accept_format('json')
        request.set_DBInstanceId(instance_id)
        response = self.client.do_action_with_exception(request)
        resp = json.loads(response)
        if len(resp["Items"]["DBInstanceTag"]) > 0:
            return resp["Items"]["DBInstanceTag"][0]["Tags"]["Tag"]
        return []

    def add_tags(self, instance_id, tag_list):
        """给实例添加一个或多个标签

        Args:
            instance_id (str): 实例id
            tag_list (list): 要添加的标签列表。格式为 [{"Key": "key1", "Value": "value1"}, {"Key": "key2", "Value": "value2"}]
        """
        request = TagResourcesRequest()
        request.set_accept_format('json')
        request.set_ResourceIds([instance_id])
        request.set_ResourceType("INSTANCE")
        request.set_Tags(tag_list)
        return self.client.do_action_with_exception(request)

    def remove_tags(self, instance_id, tag_list):
        """给实例删除一个或多个标签
        Args:
            instance_id (str): 实例id
            tag_list (list): 要删除的标签列表。格式为 [{"Key": "key1", "Value": "value1"}, {"Key": "key2", "Value": "value2"}]
        """
        request = RemoveTagsFromResourceRequest()
        request.set_accept_format('json')

        request.set_DBInstanceId(instance_id)
        request.set_Tags({item["Key"]: item["Value"] for item in tag_list})
        return self.client.do_action_with_exception(request)

    def describe_regions(self):
        """查询可用的区域列表
        """
        request = DescribeRegionsRequest()
        request.set_accept_format("json")
        request.set_AcceptLanguage("zh-CN")
        response = self.client.do_action_with_exception(request)

        return list({
            region_item["RegionId"]
            for region_item in json.loads(str(response, encoding='utf-8'))["Regions"]["RDSRegion"]
        })


