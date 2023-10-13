#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-


from aliyunsdkcore.client import AcsClient
from aliyunsdkecs.request.v20140526.AddTagsRequest import AddTagsRequest
from aliyunsdkecs.request.v20140526.RemoveTagsRequest import RemoveTagsRequest
from aliyunsdkecs.request.v20140526.StopInstanceRequest import StopInstanceRequest
from aliyunsdkecs.request.v20140526.StartInstanceRequest import StartInstanceRequest


class LibAliyunEcs:
    def __init__(self, access_id, access_key, region):
        self.region = region
        self.access_id = access_id
        self.access_key = access_key
        self.client = self.create_client()

    def create_client(self):
        return AcsClient(self.access_id, self.access_key, self.region)
    
    def stop_instances(self, instance_ids):
        """停止一个或多个实例

        Args:
            instance_ids (list): 实例id列表
        """
        if not isinstance(instance_ids, list):
            raise RuntimeError("instance_ids 变量必须是列表类型")
        
        for instance_id in instance_ids:
            request = StopInstanceRequest()
            request.set_accept_format('json')
            request.set_InstanceId(instance_id)
            self.client.do_action_with_exception(request)


    def start_instances(self, instance_ids):
        """启动一个或多个实例

        Args:
            instance_ids (list): 实例id列表
        """
        if not isinstance(instance_ids, list):
            raise RuntimeError("instance_ids 变量必须是列表类型")
        
        for instance_id in instance_ids:
            request = StartInstanceRequest()
            request.set_accept_format('json')
            request.set_InstanceId(instance_id)
            self.client.do_action_with_exception(request)

    def add_tags(self, instance_id, tag_list):
        """给实例添加一个或多个标签

        Args:
            instance_id (str): 实例id
            tag_list (list): 要添加的标签列表。格式为 [{"Key": "key1", "Value": "value1"}, {"Key": "key2", "Value": "value2"}]
        """
        return self._add_tags(instance_id, "instance", tag_list)

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
        return self._add_tags(disk_instance_id, "disk", tag_list)

    def _add_tags(self, instance_id, instance_type, tag_list):
        request = AddTagsRequest()
        request.set_accept_format('json')
        request.set_ResourceId(instance_id)
        request.set_ResourceType(instance_type)
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
