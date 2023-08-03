#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-


from aliyunsdkcore.client import AcsClient
from aliyunsdkrds.request.v20140815.TagResourcesRequest import TagResourcesRequest
from aliyunsdkr_kvstore.request.v20150101.TagResourcesRequest import TagResourcesRequest
from aliyunsdkr_kvstore.request.v20150101.UntagResourcesRequest import UntagResourcesRequest


class LibAliyunRedis:
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
            tag_list (list): 要添加的标签列表。格式为 [{"Key": "key1", "Value": "value1"}, {"Key": "key2", "Value": "value2"}]
        """
        request = TagResourcesRequest()
        request.set_accept_format('json')
        request.set_ResourceIds([instance_id])
        request.set_ResourceType("INSTANCE")
        request.set_Tags(tag_list)
        return self.client.do_action_with_exception(request)

    def remove_tags(self, instance_id, need_delete_list):
        """给实例删除一个或多个标签

        Args:
            instance_id (str): 实例id
            need_delete_list (list): 要删除的标签key列表。格式为 ["key1", "key2"]
        """
        request = UntagResourcesRequest()
        request.set_accept_format('json')
        request.set_ResourceType("INSTANCE")
        request.set_ResourceIds([instance_id])
        request.set_TagKeys(need_delete_list)
        return self.client.do_action_with_exception(request)
