#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import subprocess

from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkdcs.v2.region.dcs_region import DcsRegion
from huaweicloudsdkdcs.v2 import *

class LibHuaweiDcs:
    def __init__(self, access_id, access_key, project_id, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.project_id = None if project_id in [None, "None"] else project_id.strip()
        self.client = self.create_client()

    def create_client(self):
        credentials = BasicCredentials(self.access_id, self.access_key, self.project_id)

        return DcsClient.new_builder() \
            .with_credentials(credentials) \
            .with_region(DcsRegion.value_of(self.region)) \
            .build()

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
