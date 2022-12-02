#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from huaweicloudsdkcore.auth.credentials import GlobalCredentials
from huaweicloudsdkiam.v3.region.iam_region import IamRegion
from huaweicloudsdkiam.v3 import *


class HuaweiIam:
    def __init__(self, access_id, access_key, user_id, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.user_id = user_id
        self.client = self.create_client()

    def create_client(self):
        credentials = GlobalCredentials(self.access_id, self.access_key) \

        return IamClient.new_builder() \
            .with_credentials(credentials) \
            .with_region(IamRegion.value_of(self.region)) \
            .build()

    # 查询指定IAM用户的项目列表
    def list_projects_for_user(self, user_id):
        request = KeystoneListProjectsForUserRequest()
        request.user_id = user_id
        response = self.client.keystone_list_projects_for_user(request)
        return response.projects

    # 查询指定IAM用户指定区域的项目id
    def get_project_id(self):
        project_list = self.list_projects_for_user(self.user_id)
        for project in project_list:
            if project.name == self.region:
                return project.id
        raise Exception("未找到指定用户: {}, 指定区域: {}的项目id".format(
            self.user_id, self.region))
