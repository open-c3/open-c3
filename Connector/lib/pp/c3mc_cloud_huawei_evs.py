#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json

from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkevs.v2.region.evs_region import EvsRegion
from huaweicloudsdkevs.v2 import *


class LibHuaweiEvs:
    """
    华为云磁盘
    """
    def __init__(self, access_id, access_key, project_id, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region

        self.project_id = None if project_id in [None, "None"] else project_id.strip()
        self.client = self.create_client()

    def create_client(self):
        credentials = BasicCredentials(self.access_id, self.access_key, self.project_id)

        return EvsClient.new_builder() \
            .with_credentials(credentials) \
            .with_region(EvsRegion.value_of(self.region)) \
            .build()

    def add_tags(self, volume_id, tag_list):
        """给实例添加一个或多个标签

        Args:
            volume_id (str): 磁盘id
            tag_list (list): 要添加的标签列表。格式为 [Tag, Tag...]
        """
        request = BatchCreateVolumeTagsRequest()
        request.volume_id = volume_id
        request.body = BatchCreateVolumeTagsRequestBody(tags=tag_list, action="create")
        return self.client.batch_create_volume_tags(request)

    def remove_tags(self, volume_id, tag_list):
        """给实例删除一个或多个标签

        Args:
            volume_id (str): 磁盘id
            tag_list (list): 要删除的标签列表。格式为 [DeleteTagsOption, DeleteTagsOption...]
        """
        request = BatchDeleteVolumeTagsRequest()
        request.volume_id = volume_id
        request.body = BatchDeleteVolumeTagsRequestBody(tags=tag_list, action="delete")
        return self.client.batch_delete_volume_tags(request)
