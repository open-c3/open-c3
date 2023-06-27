#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import re
import time

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
    
    def IsolateDBInstance(self, instance_id):
        """隔离cdb实例
        """
        req = models.IsolateDBInstanceRequest()
        params = {
            "InstanceId": instance_id
        }
        req.from_json_string(json.dumps(params))

        resp = self.client.IsolateDBInstance(req)
        return json.loads(resp.to_json_string())
    
    def OfflineIsolatedInstance(self, instance_id_list):
        """立即下线隔离状态的cdb实例
        进行操作的实例状态必须为隔离状态，即通过 查询实例列表 接口查询到 Status 值为 5 的实例。
        """
        req = models.OfflineIsolatedInstancesRequest()
        params = {
            "InstanceIds": instance_id_list
        }
        req.from_json_string(json.dumps(params))

        resp = self.client.OfflineIsolatedInstances(req)
        return json.loads(resp.to_json_string())

    def _wait_cdb_until_status(self, instance_id, target_status, timeout=600):
        """等待cdb实例变为 target_status 状态
        如果超时则抛出异常

        Args:
            instance_id (str): cdb实例id
            target_status (int): cdb目标状态。可选值为 0 - 创建中; 1 - 运行中; 4 - 正在进行隔离操作; 5 - 已隔离（可在回收站恢复开机）
            timeout (int, optional): 超时时间。
        """
        start_time = time.time()
        while True:
            cdb_info = self.DescribeDBInstances(instance_id)
            if cdb_info["Status"] == target_status:
                return
            elif time.time() - start_time > timeout:
                raise RuntimeError(f"等待 {timeout} 秒后, 实例 {instance_id} 依然无法变为 {target_status} 状态")
            else:
                time.sleep(5)

    def delete_cdb_instance(self, instance_id_list):
        for instance_id in instance_id_list:
            cdb_info = self.DescribeDBInstances(instance_id)
            if cdb_info["Status"] == 0:
                # 等待cdb实例变为运行状态，创建中的实例直接隔离会出错
                self._wait_cdb_until_status(instance_id, 1, 900)

            # 官方已不建议使用返回结果中的AsyncRequestId查询处理结果            
            self.IsolateDBInstance(instance_id)

            # 等待cdb实例变为隔离状态
            self._wait_cdb_until_status(instance_id, 5, 900)

        # 立即下线隔离状态的cdb实例
        self.OfflineIsolatedInstance(instance_id_list)




