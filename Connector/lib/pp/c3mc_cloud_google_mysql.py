#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

from google.oauth2 import service_account
from googleapiclient import discovery


class GoogleMysql:
    def __init__(self, cred_json_path):
        self.cred_json_path = cred_json_path
        self.credentials = self.create_credentials()
        self.service = self.create_service()

    def create_credentials(self):
        return service_account.Credentials.from_service_account_file(self.cred_json_path)
    
    def create_service(self):
        return discovery.build('sqladmin', 'v1beta4', credentials=self.credentials)

    def get_project_id(self):
        """获取当前凭证的project_id
        """
        return self.credentials.project_id

    # settings是原始数据里的settings字段, 里面配置了新的标签
    # 因为有些字段必传，所以这里把修改后的settings整个传了过来
    def update_label(self, msyql_instance_id, settings):
        request_body = {
            "settings": settings
        }

        request = self.service.instances().update(
            project=self.project_id, instance=msyql_instance_id, body=request_body)
        request.execute()

    def list_mysql_instances(self, region):
        """根据指定的地域获取MySQL实例列表
        """
        data = []
        project_id = self.credentials.project_id
        request = self.service.instances().list(project=project_id)

        while request is not None:
            response = request.execute()
            if 'items' in response:
                data.extend(
                    item
                    for item in response['items']
                    if item['databaseVersion'].startswith('MYSQL')
                    and item['region'] == region
                )
            request = self.service.instances().list_next(previous_request=request, previous_response=response)

        return data
