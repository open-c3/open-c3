#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

from pprint import pprint
from google.oauth2 import service_account
from googleapiclient import discovery


class MysqlTag:
    def __init__(self, cred_json_path, instance_id):
        self.cred_json_path = cred_json_path
        self.instance_id = instance_id

        credentials = service_account.Credentials.from_service_account_file(
            self.cred_json_path)
        self.project_id = credentials.project_id
        self.service = discovery.build(
            'sqladmin', 'v1beta4', credentials=credentials)

    # settings是原始数据里的settings字段, 里面配置了新的标签
    # 因为有些字段必传，所以这里把修改后的settings整个传了过来
    def update_settings(self, settings):
        request_body = {
            "settings": settings
        }

        request = self.service.instances().update(
            project=self.project_id, instance=self.instance_id, body=request_body)
        request.execute()
