#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-


from aliyunsdkcore.client import AcsClient
from aliyunsdkslb.request.v20140515.AddTagsRequest import AddTagsRequest
from aliyunsdkslb.request.v20140515.RemoveTagsRequest import RemoveTagsRequest


class LibAliyunSlb:
    def __init__(self, access_id, access_key, region):
        self.region = region
        self.access_id = access_id
        self.access_key = access_key
        self.client = self.create_client()

    def create_client(self):
        return AcsClient(self.access_id, self.access_key, self.region)

    def add_tags(self, instance_id, tag_list):
        """给实例添加一个或多个标签

        Args:
            instance_id (str): 实例id
            tag_list (list): 要添加的标签列表。格式为 [{"TagKey": "key1", "TagValue": "value1"}, {"TagKey": "key2", "TagValue": "value2"}]
        """
        request = AddTagsRequest()
        request.set_accept_format("json")
        request.set_LoadBalancerId(instance_id)
        request.set_Tags(tag_list)
        return self.client.do_action_with_exception(request)

    def remove_tags(self, instance_id, tag_list):
        """给实例删除一个或多个标签

        Args:
            instance_id (str): 实例id
            tag_list (list): 要删除的标签列表。格式为 [{"TagKey": "key1", "TagValue": "value1"}, {"TagKey": "key2", "TagValue": "value2"}]
        """
        request = RemoveTagsRequest()
        request.set_accept_format("json")
        request.set_LoadBalancerId(instance_id)
        request.set_Tags(tag_list)
        return self.client.do_action_with_exception(request)
