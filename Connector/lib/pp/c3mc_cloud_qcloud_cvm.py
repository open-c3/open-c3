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


sys.path.append("/data/Software/mydan/Connector/lib/pp")
from c3mc_utils import safe_run_command


class QcloudCvm:
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

    def run_instances(self, request):
        return self.cvm_client.RunInstances(request)

    def stop_instances(self, instance_ids):
        """停止实例

        Args:
            instance_ids (list): 实例id列表
        """
        req = cvm_models.StopInstancesRequest()
        params = {
            "InstanceIds": instance_ids
        }
        req.from_json_string(json.dumps(params))

        res = self.cvm_client.StopInstances(req)
        print(f"停止实例: {' '.join(instance_ids)}, 响应: {res.to_json_string()}")
        return res

    def start_instances(self, instance_ids):
        """启动实例

        Args:
            instance_ids (list): 实例id列表
        """
        req = cvm_models.StartInstancesRequest()
        params = {
            "InstanceIds": instance_ids
        }
        req.from_json_string(json.dumps(params))

        res = self.cvm_client.StartInstances(req)
        print(f"启动实例: {' '.join(instance_ids)}, 响应: {res.to_json_string()}")
        return res
    
    def reset_instances_type(self, instance_ids, instance_type):
        """本接口 (ResetInstancesType) 用于调整实例的机型。

        Args:
            instance_ids (list): cvm实例id列表
            instance_type (str): 实例类型
        """
        req = cvm_models.ResetInstancesTypeRequest()
        params = {
            "InstanceIds": instance_ids,
            "InstanceType": instance_type
        }
        req.from_json_string(json.dumps(params))

        resp = self.cvm_client.ResetInstancesType(req)
        return json.loads(resp.to_json_string())

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
        
        cvm_info = self.show_cvm(instance_id)
        
        if cvm_info["InstanceState"] in ["SHUTDOWN", "TERMINATING"]:
            return
        
        if cvm_info["InstanceState"] not in ["STOPPING", "STOPPED"]:
            self.stop_instances([instance_id])
        
        self.wait_cvm_until_status(instance_id, "STOPPED")

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

    def list_cvms(self):
        """查询区域下的cvm列表
        """
        def get_refined_cvm_list(cvm_list):
            for i in range(len(cvm_list)):
                cvm_list[i]["PrivateIp"] = ""
                cvm_list[i]["PublicIp"] = ""
                if len(cvm_list[i]["PrivateIpAddresses"]) > 0:
                    cvm_list[i]["PrivateIp"] = cvm_list[i]["PrivateIpAddresses"][0]
                if "PublicIpAddresses" in cvm_list[i] and cvm_list[i]["PublicIpAddresses"] is not None:
                    cvm_list[i]["PublicIp"] = cvm_list[i]["PublicIpAddresses"][0]
            return cvm_list

        result = []
        req = cvm_models.DescribeInstancesRequest()
        for i in range(1, sys.maxsize):
            params = {
                "Limit": 100,
                "Offset": (i - 1) * 100
            }
            req.from_json_string(json.dumps(params))

            resp = self.cvm_client.DescribeInstances(req)

            cvm_list = json.loads(resp.to_json_string())["InstanceSet"]

            if len(cvm_list) == 0:
                break
            result.extend(get_refined_cvm_list(cvm_list))
        return result
    
    def list_instance_types(self, zone, instance_charge_type):
        """列出cvm实例类型列表

        Args:
            zone (str): 可用区
            instance_charge_type (str): PREPAID: 表示预付费，即包年包月
                                        POSTPAID_BY_HOUR: 表示后付费, 即按量计费
        """
        req = cvm_models.DescribeZoneInstanceConfigInfosRequest()
        params = {
            "Filters": [
                {
                    "Name": "zone",
                    "Values": [ zone ]
                },
                {
                    "Name": "instance-charge-type",
                    "Values": [ instance_charge_type ]
                }
            ]
        }
        req.from_json_string(json.dumps(params))
        resp = json.loads(self.cvm_client.DescribeZoneInstanceConfigInfos(req).to_json_string())
        return sorted(resp["InstanceTypeQuotaSet"], key=lambda x: (x['InstanceType'], x['Cpu'], x['Memory']), reverse=False)


    def wait_cvm_until_status(self, instance_id, target_status, timeout=900):
        """等待cvm实例进入目标状态

        Args:
            instance_id (string): cvm实例ID
            target_status: (string)。cvm的目标状态。
                                    取值范围：
                                        PENDING：表示创建中
                                        LAUNCH_FAILED：表示创建失败
                                        RUNNING：表示运行中
                                        STOPPED：表示关机
                                        STARTING：表示开机中
                                        STOPPING：表示关机中
                                        REBOOTING：表示重启中
                                        SHUTDOWN：表示停止待销毁
                                        TERMINATING：表示销毁中。
            timeout (int, optional): 超时时间, 单位秒
        """
        start_time = time.time()
        while True:
            print(f"等待实例处于 {target_status} 状态, instance_id: {instance_id}")
            instance_info = self.show_cvm(instance_id)

            if instance_info["InstanceState"] == target_status:
                return
            elif time.time() - start_time > timeout:
                raise RuntimeError(f"等待实例 {instance_id} 变为 {target_status} 状态，但是超时了，超时时间为: {timeout}")
            else:
                time.sleep(5)

    def wait_until_cvm_instance_type(self, instance_id, target_instance_type, timeout=1800):
        """等待实例的机器类型变为目标机器类型

        调用修改cvm实例类型的接口后，需要等待异步操作结束。官方给出的方法是持续调用该接口查询机器类型

        Args:
            instance_id (string): cvm实例ID
            target_instance_type (string): 目标机器类型。机器类型的值请参考官方，格式类似于: S5.2xLarge
            timeout (int, optional): 超时时间, 单位秒
        """
        start_time = time.time()
        while True:
            print(f"等待实例类型变为 {target_instance_type}, instance_id: {instance_id}")
            instance_info = self.show_cvm(instance_id)

            if instance_info["InstanceType"] == target_instance_type and instance_info["LatestOperationState"] == "SUCCESS":
                print(f"实例类型成功变为 {target_instance_type}, instance_id: {instance_id}")
                return
            elif time.time() - start_time > timeout:
                raise RuntimeError(f"等待实例类型变为 {target_instance_type}，但是超时了，超时时间为: {timeout}")
            else:
                time.sleep(5)

    def fuzzy_query_instance_list_v1(self, keyword):
        """模糊查询cvm列表 

        该版本的接口从openc3数据库查询数据, 这样做的好处是查询会很快
        将来有需要可以实现v2版本从云上查询
        """
        output = safe_run_command(["c3mc-device-data-get", "curr", "compute", "qcloud-cvm", "名称", "所在可用区", "ProjectName", "InstanceId"])

        data = []
        for line in output.split("\n"):
            line = line.strip()
            if line == "":
                continue

            parts = line.split()

            if len(parts) != 4:
                continue

            if keyword not in parts[0] and keyword not in parts[2]:
                continue

            data.append({
                "name": parts[0],
                "zone": parts[1],
                "project_name": parts[2],
                "instance_id": parts[3],
            })

        return data
