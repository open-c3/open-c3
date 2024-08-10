#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import sys, json
from huaweicloudsdkcore.auth.credentials import GlobalCredentials, BasicCredentials
from huaweicloudsdkcore.exceptions import exceptions
from huaweicloudsdkdcs.v2 import *
from huaweicloudsdkiam.v3 import *

class LibHuaweiDcs:
    def __init__(self, access_id, access_key, project_id, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.project_id = project_id if project_id not in [None, "None"] else self.get_project_id()
        self.client = self.create_client()

    def get_project_id(self):
        # 定义 IAM 端点映射
        iam_endpoints = {
            "eu-west-101": "https://iam.myhuaweicloud.eu",  # 都柏林地区
            "default": "https://iam.myhuaweicloud.com"  # 默认端点
        }

        # 选择合适的 IAM 端点
        iam_endpoint = iam_endpoints.get(self.region, iam_endpoints["default"])

        credentials = GlobalCredentials(self.access_id, self.access_key)
        iam_client = IamClient.new_builder() \
            .with_credentials(credentials) \
            .with_endpoint(iam_endpoint) \
            .build()

        try:
            request = KeystoneListProjectsRequest()
            response = iam_client.keystone_list_projects(request)
            for project in response.projects:
                if project.name == self.region:
                    return project.id

            raise Exception(f"No project found for region {self.region}")
        except exceptions.ClientRequestException as e:
            print(f"Failed to get project ID: {e}")
            sys.exit(1)

    def get_endpoint(self, region_id):
        # 处理都柏林地区的特殊情况
        if region_id == "eu-west-101":
            return f"https://dcs.{region_id}.myhuaweicloud.eu"
        
        return f"https://dcs.{region_id}.myhuaweicloud.com"

    def create_client(self):
        credentials = BasicCredentials(self.access_id, self.access_key, self.project_id)
        endpoint = self.get_endpoint(self.region)
        return (
            DcsClient.new_builder() \
            .with_credentials(credentials) \
            .with_endpoint(endpoint) \
            .build()
        )

    def add_tags(self, instance_id, tag_list):
        """给实例添加一个或多个标签

        Args:
            instance_id (str): 实例id
            tag_list (list): 要添加的标签列表。格式为 [ResourceTag, ResourceTag]
        """
        request = BatchCreateOrDeleteTagsRequest()
        request.instance_id = instance_id
        request.body = CreateOrDeleteInstanceTags(tags=tag_list, action="create")
        return self.client.batch_create_or_delete_tags(request)

    def remove_tags(self, instance_id, tag_list):
        """给实例删除一个或多个标签

        Args:
            instance_id (str): 实例id
            tag_list (list): 要删除的标签列表。格式为 [ResourceTag, ResourceTag]
        """
        request = BatchCreateOrDeleteTagsRequest()
        request.instance_id = instance_id
        request.body = CreateOrDeleteInstanceTags(tags=tag_list, action="delete")
        return self.client.batch_create_or_delete_tags(request)

    def get_instance_details(self, instance_id):
        try:
            request = ShowInstanceRequest(instance_id=instance_id)
            response = self.client.show_instance(request)
            return response
        except exceptions.ClientRequestException as e:
            print(f"Error occurred while fetching instance details: {e}")
            return None

    def get_available_memory_sizes(self, instance_id, instance_type):
        try:
            request = ListFlavorsRequest()
            request.instance_id = instance_id
            response = self.client.list_flavors(request)
            flavors = [flavor for flavor in response.flavors if flavor.cache_mode == instance_type]
            return flavors          
        except exceptions.ClientRequestException as e:
            print(f"Error occurred while fetching available specs: {e}")
            return []

    def determine_target_memory(self, current_memory, available_memories_dict, action):
        available_memories_set = {
            (lambda s: int(s) if s.isdigit() else float(s))(memory)
            for memory in available_memories_dict.keys()
        }

        # 将当前规格添加到集合中
        available_memories_set.add(current_memory)

        # 将集合转换为列表并排序
        available_memories = sorted(available_memories_set)
        current_index = available_memories.index(current_memory)

        if action == "upgrade" and current_index < len(available_memories) - 1:
            return available_memories[current_index + 1]
        elif action == "downgrade" and current_index > 0:
            return available_memories[current_index - 1]
        return None

    def change_instance_memory(self, instance_id, target_memory, instance_spec_code):
        try:
            request = ResizeInstanceRequest(
                instance_id=instance_id,
                body=ResizeInstanceBody(
                    spec_code = instance_spec_code,
                    new_capacity = target_memory
                )
            )
            self.client.resize_instance(request)
        except exceptions.ClientRequestException as e:
            print(f"Error occurred while resizing instance: {e}")
            sys.exit(1)

    def perform_resize(self, instance_id, action):
        instance_details = self.get_instance_details(instance_id)
        result = {"error": "未知错误"}

        if instance_details:
            current_memory = instance_details.max_memory / 1024

            instance_type = instance_details.cache_mode

            available_memories_dict = {
                flavor.capacity[0]: flavor.spec_code
                for flavor in self.get_available_memory_sizes(instance_id,instance_type)
            }
            next_memory = self.determine_target_memory(current_memory, available_memories_dict, action)

            if next_memory:
                instance_spec_code = available_memories_dict[str(next_memory)]
                self.change_instance_memory(instance_id, next_memory, instance_spec_code)
                result = {
                    "action": f"{action}",
                    "current_memory": f"{current_memory} GB",
                    "target_memory": f"{next_memory} GB"
                }
            else:
                result = {
                    "error": f"没有合适的内存大小可供{'升级' if action == 'upgrade' else '降配'}"
                }
        else:
            result = {
                "error": "无法获取实例详细信息"
            }
        return result
