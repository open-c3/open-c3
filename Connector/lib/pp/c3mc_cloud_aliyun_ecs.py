#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-


from aliyunsdkcore.client import AcsClient
from aliyunsdkecs.request.v20140526.AddTagsRequest import AddTagsRequest
from aliyunsdkecs.request.v20140526.RemoveTagsRequest import RemoveTagsRequest


class LibAliyunEcs:
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
        request = AddTagsRequest()
        request.set_accept_format('json')
        request.set_ResourceId(instance_id)
        request.set_ResourceType("instance")
        request.set_Tags(tag_list)
        return self.client.do_action_with_exception(request)

    def remove_tags(self, instance_id, tag_list):
        """给实例删除一个或多个标签

        Args:
            instance_id (str): 实例id
            tag_list (list): 要删除的标签列表。格式为 [{"Key": "key1", "Value": "value1"}, {"Key": "key2", "Value": "value2"}]
        """
        request = RemoveTagsRequest()
        request.set_accept_format('json')
        request.set_ResourceId(instance_id)
        request.set_ResourceType("instance")

        for index, item in enumerate(tag_list):
            request.add_query_param(f'Tag.{index + 1}.Key', item["Key"])
            request.add_query_param(f'Tag.{index + 1}.Value', item["Value"])

        return self.client.do_action_with_exception(request)

    def add_disk_tags(self, disk_instance_id, tag_list):
        """给磁盘添加一个或多个标签

        Args:
            disk_instance_id (str): 磁盘id
            tag_list (list): 要添加的标签列表。格式为 [{"Key": "key1", "Value": "value1"}, {"Key": "key2", "Value": "value2"}]
        """
        request = AddTagsRequest()
        request.set_accept_format('json')
        request.set_ResourceId(disk_instance_id)
        request.set_ResourceType("disk")
        request.set_Tags(tag_list)
        return self.client.do_action_with_exception(request)

    def remove_disk_tags(self, disk_instance_id, tag_list):
        """给磁盘删除一个或多个标签

        Args:
            disk_instance_id (str): 磁盘id
            tag_list (list): 要删除的标签列表。格式为 [{"Key": "key1", "Value": "value1"}, {"Key": "key2", "Value": "value2"}]
        """
        request = RemoveTagsRequest()
        request.set_accept_format('json')
        request.set_ResourceId(disk_instance_id)
        request.set_ResourceType("disk")
        request.set_Tags(tag_list)
        return self.client.do_action_with_exception(request)
