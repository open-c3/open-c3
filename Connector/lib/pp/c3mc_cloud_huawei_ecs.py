#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json

from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkecs.v2.region.ecs_region import EcsRegion
from huaweicloudsdkecs.v2 import *
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkevs.v2.region.evs_region import EvsRegion
from huaweicloudsdkevs.v2 import *


class LibHuaweiEcs:
    def __init__(self, access_id, access_key, project_id, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region

        self.project_id = None if project_id in [None, "None"] else project_id.strip()
        self.client = self.create_client()

    def create_client(self):
        credentials = BasicCredentials(self.access_id, self.access_key, self.project_id)

        return (
            EcsClient.new_builder()
            .with_credentials(credentials)
            .with_region(EcsRegion.value_of(self.region))
            .build()
        )

    def stop_instances(self, instance_ids):
        """停止一个或多个实例

        Args:
            instance_ids (list): 实例id列表
        """
        if not isinstance(instance_ids, list):
            raise RuntimeError("instance_ids 变量必须是列表类型")

        request = BatchStopServersRequest()
        listServersOsstop = [ServerId(id=instance_id) for instance_id in instance_ids]
        osstopbody = BatchStopServersOption(servers=listServersOsstop)
        request.body = BatchStopServersRequestBody(os_stop=osstopbody)
        return self.client.batch_stop_servers(request)

    def start_instances(self, instance_ids):
        """启动一个或多个实例

        Args:
            instance_ids (list): 实例id列表
        """
        if not isinstance(instance_ids, list):
            raise RuntimeError("instance_ids 变量必须是列表类型")
        
        request = BatchStartServersRequest()
        listServersOsstop = [ServerId(id=instance_id) for instance_id in instance_ids]
        osstopbody = BatchStartServersOption(servers=listServersOsstop)
        request.body = BatchStartServersRequestBody(os_start=osstopbody)
        return self.client.batch_start_servers(request)


    def add_tags(self, instance_id, tag_list):
        """给实例添加一个或多个标签

        Args:
            instance_id (str): 实例id
            tag_list (list): 要添加的标签列表。格式为 [ServerTag, ServerTag...]
        """
        request = BatchCreateServerTagsRequest()
        request.server_id = instance_id
        request.body = BatchCreateServerTagsRequestBody(tags=tag_list, action="create")
        return self.client.batch_create_server_tags(request)

    def remove_tags(self, instance_id, tag_list):
        """给实例删除一个或多个标签

        Args:
            instance_id (str): 实例id
            tag_list (list): 要删除的标签列表。格式为 [ServerTag, ServerTag...]
        """

        request = BatchDeleteServerTagsRequest()
        request.server_id = instance_id
        request.body = BatchDeleteServerTagsRequestBody(
            tags=tag_list,
            action="delete"
        )
        return self.client.batch_delete_server_tags(request)

    def add_disk_tags(self, volume_id, tag_list):
        """给磁盘添加一个或多个标签

        Args:
            volume_id (str): 磁盘实例id
            tag_list (list): 要添加的标签列表。格式为 [Tag, Tag...]
        """

        request = BatchCreateVolumeTagsRequest()
        request.volume_id = volume_id
        request.body = BatchCreateVolumeTagsRequestBody(tags=tag_list, action="create")
        return self.client.batch_create_volume_tags(request)

    def remove_disk_tags(self, volume_id, tag_list):
        """给磁盘删除一个或多个标签

        Args:
            volume_id (str): 磁盘实例id
            tag_list (list): 要删除的标签列表。格式为 [DeleteTagsOption, DeleteTagsOption...]
        """
        request = BatchDeleteVolumeTagsRequest()
        request.volume_id = volume_id
        request.body = BatchDeleteVolumeTagsRequestBody(tags=tag_list, action="delete")
        return self.client.batch_delete_volume_tags(request)
