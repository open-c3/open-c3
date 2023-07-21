#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import time
import sys
import subprocess

from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.cdb.v20170320 import cdb_client, models


sys.path.append("/data/Software/mydan/Connector/lib/pp")
from c3mc_utils import sleep_time_for_limiting

max_times_describe_tags = 20


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

    def describe_cdb_zone_config(self):
        """查询数据库可用区及售卖规
        """
        req = models.DescribeCdbZoneConfigRequest()
        params = {}
        req.from_json_string(json.dumps(params))

        resp = self.client.DescribeCdbZoneConfig(req)
        return json.loads(resp.to_json_string())

    def describe_param_templates(self, engine_type, engine_version):
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

    def describe_default_params(self, engine_type, engine_version):
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

    def open_wan_service(self, instance_id):
        """开通实例外网访问
        """
        req = models.OpenWanServiceRequest()
        params = {
            "InstanceId": instance_id
        }
        req.from_json_string(json.dumps(params))

        resp = self.client.OpenWanService(req)
        return json.loads(resp.to_json_string())

    def describe_db_instances(self, instance_id):
        """查询cdb实例详情
        """
        req = models.DescribeDBInstancesRequest()
        params = {
            "InstanceIds": [ instance_id ]
        }
        req.from_json_string(json.dumps(params))

        resp = self.client.DescribeDBInstances(req)
        return json.loads(resp.to_json_string())["Items"][0]
    
    def isolate_db_instance(self, instance_id):
        """隔离cdb实例
        """
        req = models.IsolateDBInstanceRequest()
        params = {
            "InstanceId": instance_id
        }
        req.from_json_string(json.dumps(params))

        resp = self.client.IsolateDBInstance(req)
        return json.loads(resp.to_json_string())

    def release_isolate_db_instance(self, instance_id_list):
        """解除隔离cdb实例
        """
        req = models.ReleaseIsolatedDBInstancesRequest()
        params = {
            "InstanceIds": instance_id_list
        }
        req.from_json_string(json.dumps(params))

        # 返回的resp是一个ReleaseIsolatedDBInstancesResponse的实例，与请求对象对应
        resp = self.client.ReleaseIsolatedDBInstances(req)
        return json.loads(resp.to_json_string())
    
    def offline_isolated_instances(self, instance_id_list):
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

    def describe_backups(self, instance_id):
        """查询数据备份文件列表
        """
        result = []

        req = models.DescribeBackupsRequest()
        for i in range(sys.maxsize):
            params = {
                "InstanceId": instance_id,
                "Limit": 100,
                "Offset": i * 100
            }
            req.from_json_string(json.dumps(params))

            resp = self.client.DescribeBackups(req)

            backup_list = json.loads(resp.to_json_string())["Items"]

            if len(backup_list) == 0:
                break
            result.extend(backup_list)
        return result
    
    def delete_backup(self, instance_id, backup_id):
        req = models.DeleteBackupRequest()
        params = {
            "InstanceId": instance_id,
            "BackupId": backup_id
        }
        req.from_json_string(json.dumps(params))

        self.client.DeleteBackup(req)


    def wait_cdb_until_status(self, instance_id, target_status, timeout=600):
        """等待cdb实例变为 target_status 状态
        如果超时则抛出异常

        Args:
            instance_id (str): cdb实例id
            target_status (int): cdb目标状态。可选值为 0 - 创建中; 1 - 运行中; 4 - 正在进行隔离操作; 5 - 已隔离（可在回收站恢复开机）
            timeout (int, optional): 超时时间。
        """
        start_time = time.time()
        while True:
            cdb_info = self.describe_db_instances(instance_id)
            if cdb_info["Status"] == target_status:
                return
            elif time.time() - start_time > timeout:
                raise RuntimeError(f"等待 {timeout} 秒后, 实例 {instance_id} 依然无法变为 {target_status} 状态")
            else:
                time.sleep(5)
    
    def delete_buckups_of_cdb(self, instance_id):
        backups_list = self.describe_backups(instance_id)

        for backup in backups_list:
            if backup["Way"] == "manual":
                self.delete_backup(instance_id, backup["BackupId"])


    def delete_cdb_instance(self, instance_id_list, if_delete_backup=False):
        for instance_id in instance_id_list:
            if if_delete_backup:
                # 删除手动备份
                # 只有运行中的数据库实例才能操作删除备份
                self.delete_buckups_of_cdb(instance_id)

            cdb_info = self.describe_db_instances(instance_id)
            if cdb_info["Status"] == 0:
                # 等待cdb实例变为运行状态，创建中的实例直接隔离会出错
                self.wait_cdb_until_status(instance_id, 1, 900)

            # 官方已不建议使用返回结果中的AsyncRequestId查询处理结果            
            self.isolate_db_instance(instance_id)

            # 等待cdb实例变为隔离状态
            self.wait_cdb_until_status(instance_id, 5, 900)

        # 立即下线隔离状态的cdb实例
        self.offline_isolated_instances(instance_id_list)
    

    def create_accounts(self, instance_id, user, host, password):
        """创建数据库账号

        Args:
            instance_id (str): 数据库实例的id
            user (str): 新账户的名称
            host (str): 新账户的域名
            password (str): 密码
        """
        req = models.CreateAccountsRequest()
        params = {
            "InstanceId": instance_id,
            "Accounts": [
                {
                    "User": user,
                    "Host": host
                }
            ],
            "Password": password
        }
        req.from_json_string(json.dumps(params))

        resp = self.client.CreateAccounts(req)
        return json.loads(resp.to_json_string())

    
    def modify_account_privileges(self, instance_id, user, host, global_privileges):
        """本接口用于修改云数据库的账户的权限信息。

        Args:
            instance_id (str): 数据库实例的id
            user (str): 数据库的账号
            host (str): 新账户的域名
            global_privileges (list): 全局权限列表。可选值为：
                                "SELECT","INSERT","UPDATE","DELETE","CREATE", 
                                "PROCESS", "DROP","REFERENCES","INDEX","ALTER",
                                "SHOW DATABASES","CREATE TEMPORARY TABLES",
                                "LOCK TABLES","EXECUTE","CREATE VIEW","SHOW VIEW",
                                "CREATE ROUTINE","ALTER ROUTINE","EVENT",
                                "TRIGGER","CREATE USER","RELOAD","REPLICATION CLIENT","REPLICATION SLAVE"。
        """
        req = models.ModifyAccountPrivilegesRequest()
        params = {
            "InstanceId": instance_id,
            "Accounts": [
                {
                    "User": user,
                    "Host": host
                }
            ],
            "GlobalPrivileges": global_privileges
        }
        req.from_json_string(json.dumps(params))

        resp = self.client.ModifyAccountPrivileges(req)
        return json.loads(resp.to_json_string())
