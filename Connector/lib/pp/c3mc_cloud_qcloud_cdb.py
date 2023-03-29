#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import re

from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.cdb.v20170320 import cdb_client, models


class QcloudCdb:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        """创建cdb sdk客户端
        """
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "cdb.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return cdb_client.CdbClient(cred, self.region, clientProfile)

    def DescribeCdbZoneConfig(self):
        """查询数据库可用区及售卖规
        """
        req = models.DescribeCdbZoneConfigRequest()
        params = {}
        req.from_json_string(json.dumps(params))

        resp = self.client.DescribeCdbZoneConfig(req)
        return json.loads(resp.to_json_string())

    def DescribeParamTemplates(self, engine_type, engine_version):
        """查询参数模板列表
        """
        req = models.DescribeParamTemplatesRequest()
        params = {
            "EngineVersions": [ engine_version ],
            "EngineTypes": [ engine_type ]
        }
        req.from_json_string(json.dumps(params))

        resp = self.client.DescribeParamTemplates(req)
        return json.loads(resp.to_json_string())["Items"]

    def DescribeDefaultParams(self, engine_type, engine_version):
        """查询默认的可设置参数列表
        """
        req = models.DescribeDefaultParamsRequest()
        params = {
            "EngineVersion": engine_version,
            "EngineType": engine_type
        }
        req.from_json_string(json.dumps(params))

        resp = self.client.DescribeDefaultParams(req)
        return json.loads(resp.to_json_string())["Items"]

    def OpenWanService(self, instance_id):
        """开通实例外网访问
        """
        req = models.OpenWanServiceRequest()
        params = {
            "InstanceId": instance_id
        }
        req.from_json_string(json.dumps(params))

        resp = self.client.OpenWanService(req)
        return json.loads(resp.to_json_string())

    def DescribeDBInstances(self, instance_id):
        """查询cdb实例详情
        """
        req = models.DescribeDBInstancesRequest()
        params = {
            "InstanceIds": [ instance_id ]
        }
        req.from_json_string(json.dumps(params))

        resp = self.client.DescribeDBInstances(req)
        return json.loads(resp.to_json_string())["Items"][0]
