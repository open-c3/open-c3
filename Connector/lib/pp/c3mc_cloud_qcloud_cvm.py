#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import sys
import time

from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.cvm.v20170312 import cvm_client, models as cvm_models
from tencentcloud.cbs.v20170312 import cbs_client, models as cbs_models


class Cvm:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.cvm_client = self.create_cvm_client()
        self.cbs_client = self.create_cbs_client()

    def create_cvm_client(self):
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "cvm.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return cvm_client.CvmClient(cred, self.region, clientProfile)

    def create_cbs_client(self):
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "cbs.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return cbs_client.CbsClient(cred, self.region, clientProfile)

    def show_cvm(self, instance_id):
        req = cvm_models.DescribeInstancesRequest()
        params = {
            "InstanceIds": [instance_id]
        }
        req.from_json_string(json.dumps(params))
        resp = self.cvm_client.DescribeInstances(req)
        return json.loads(resp.to_json_string())["InstanceSet"][0]

    def stop_instances(self, instance_id):
        req = cvm_models.StopInstancesRequest()
        params = {
            "InstanceIds": [instance_id]
        }
        req.from_json_string(json.dumps(params))

        res = self.cvm_client.StopInstances(req)
        print(f"停止实例: {instance_id}, 响应: {res.to_json_string()}")
        return res

    def terminate_instances(self, instance_id, delete_disk_snapshot):
        """
        回收cvm实例, 同时会回收该cvm关联的数据盘
        """
        def wait_for_disk_unattached(disk_id, timeout=600):
            """
            等待磁盘成功卸载的超时时间默认为10分钟
            """
            start_time = time.time()
            while True:
                req = cbs_models.DescribeDisksRequest()
                req.DiskIds = [disk_id]
                resp = self.cbs_client.DescribeDisks(req)
                disk_status = resp.DiskSet[0].DiskState
                if disk_status == "UNATTACHED":
                    return True
                elif time.time() - start_time > timeout:
                    return False
                else:
                    time.sleep(5)

        # 获取实例磁盘信息
        req = cvm_models.DescribeInstancesRequest()
        req.InstanceIds = [instance_id]
        resp = self.cvm_client.DescribeInstances(req)
        if len(resp.InstanceSet) == 0:
            print(f"实例: {instance_id} 的详情未查询到，可能在工单其他操作时间段资源已被释放")
            return

        instance = resp.InstanceSet[0]
        data_disk_ids = []
        for disk in instance.DataDisks:
            data_disk_ids.append(disk.DiskId)

        print(f"实例: {instance_id}, 磁盘id列表: {data_disk_ids}")

        # 卸载并删除磁盘
        for disk_id in data_disk_ids:
            req = cbs_models.DetachDisksRequest()
            req.DiskIds = [disk_id]
            req.InstanceId = instance_id
            self.cbs_client.DetachDisks(req)

            if wait_for_disk_unattached(disk_id):
                print(f"实例: {instance_id}, 磁盘: {disk_id}, 卸载成功")
                req = cbs_models.TerminateDisksRequest()
                req.DiskIds = [disk_id]
                req.DeleteSnapshot = int(delete_disk_snapshot)
                res = self.cbs_client.TerminateDisks(req)
                print(f"实例: {instance_id}, 磁盘: {disk_id}, 删除结果: {res.to_json_string()}")
            else:
                print(f"实例: {instance_id}, 磁盘: {disk_id}, 卸载超时，未能删除", file=sys.stderr)
                exit(1)

        # 删除cvm实例
        req = cvm_models.TerminateInstancesRequest()
        params = {
            "InstanceIds": [instance_id]
        }
        req.from_json_string(json.dumps(params))

        res = self.cvm_client.TerminateInstances(req)
        print(f"回收cvm实例: {instance_id}, 结果: {res.to_json_string()}")
        return res
