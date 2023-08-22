#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-
import sys
import time
import json

import boto3


sys.path.append("/data/Software/mydan/Connector/lib/pp")
from c3mc_utils import safe_run_command


class LibRds:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()
        self.page_size = 100

    def create_client(self):
        endpoint_url = f"https://rds.{self.region}.amazonaws.com"
        if self.region.startswith("cn"):
            endpoint_url = f"https://rds.{self.region}.amazonaws.com.cn"

        client = boto3.client(
            "rds",
            endpoint_url=endpoint_url,
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )
        return client

    def list_db_snapshot(self):
        def get_instances_from_response(response_data):
            data = response_data["DBSnapshots"]
            for instance in data:
                instance["RegionId"] = self.region
            return data

        def get_data(marker=""):
            response = self.client.describe_db_snapshots(
                MaxRecords=self.page_size, Marker=marker, IncludeShared=True, IncludePublic=False)
            data = get_instances_from_response(response)

            res = {
                "marker": "",
                "data_list": data,
            }
            if "Marker" in response:
                res["marker"] = response["Marker"]
            return res

        result = []
        res = get_data("")
        result.extend(res["data_list"])
        marker = res["marker"]

        while marker != "":
            res = get_data(marker)
            result.extend(res["data_list"])
            marker = res["marker"]
        return result

    def add_tags(self, arn, tag_list):
        """给实例添加一个或多个标签

        Args:
            arn: 资源arn
            tag_list (list): 要添加的标签列表。格式为 [{"Key": "key1", "Value": "value1"}, {"Key": "key2", "Value": "value2"}]
        """
        return self.client.add_tags_to_resource(
            ResourceName=arn,
            Tags=tag_list
        )

    def remove_tags(self, arn, need_delete_list):
        """给实例删除一个或多个标签

        Args:
            arn: 资源arn
            need_delete_list (list): 要删除的标签key列表。格式为 ["key1", "key2"]
        """
        return self.client.remove_tags_from_resource(
            ResourceName=arn,
            TagKeys=need_delete_list
        )

    def get_local_instance_list_v1(self, account, region):
        """根据账号和区域查询rds列表

        该版本的接口从c3本地查询数据, 这样查询会很快
        """
        output = safe_run_command([
            "c3mc-device-data-get", "curr", "database", "aws-rds", "account", "区域", "名称", "状态", "实例ID"
        ])

        data = []
        for line in output.split("\n"):
            line = line.strip()
            if line == "":
                continue

            parts = line.split()

            if len(parts) != 5:
                continue

            if parts[0] != account or parts[1] != region:
                continue

            data.append({
                "Name": parts[2],
                "Status": parts[3],
                "Arn": parts[4],
            })

        return sorted(data, key=lambda x: (x['Name'].lower()), reverse=False)
    
    def describe_db_instances(self, db_instance_identifier):
        """查询rds实例信息

        Args:
            db_instance_identifier (str): rds实例id
        Returns:
            dict: rds实例信息
        """
        try:
            resp = self.client.describe_db_instances(
                DBInstanceIdentifier=db_instance_identifier,
            )
        except Exception as e:
            if "not found" in str(e):
                return None
            else:
                raise RuntimeError(f"查询rds实例 {db_instance_identifier} 信息失败") from e

        return resp["DBInstances"][0]

    def describe_db_clusters(self, db_cluster_identifier):
        """查询指定rds集群详情

        Args:
            db_cluster_identifier (str): rds集群id
        Returns:
            dict: rds实例信息
        """
        try:
            resp = self.client.describe_db_clusters(
                DBClusterIdentifier=db_cluster_identifier,
            )
        except Exception as e:
            if "not found" in str(e):
                return None
            else:
                raise RuntimeError(f"查询rds集群 {db_cluster_identifier} 信息失败") from e

        return resp["DBClusters"][0]

    def describe_db_clusters_v2(self):
        """查询rds集群列表
        """
        db_cluster_list = []
        next_marker = None

        while True:
            if next_marker:
                response = self.client.describe_db_clusters(Marker=next_marker, MaxRecords=100)
            else:
                response = self.client.describe_db_clusters(MaxRecords=100)

            db_cluster_list.extend(response['DBClusters'])

            # 检查是否有更多分页
            if 'Marker' in response:
                next_marker = response['Marker']
            else:
                break
        
        for i in range(len(db_cluster_list)):
            db_cluster_list[i]["RegionId"] = self.region

        return db_cluster_list

    def describe_db_instance_list_of_cluster(self, db_cluster_identifier):
        """根据rds集群id查询rds列表
        """
        db_instance_list = []
        next_marker = None

        filters=[
            {
                'Name': 'db-cluster-id',
                'Values': [
                    db_cluster_identifier,
                ]
            },
        ]

        while True:
            if next_marker:
                response = self.client.describe_db_instances(Marker=next_marker, Filters=filters, MaxRecords=100)
            else:
                response = self.client.describe_db_instances(Filters=filters, MaxRecords=100)

            db_instance_list.extend(response['DBInstances'])

            # 检查是否有更多分页
            if 'Marker' in response:
                next_marker = response['Marker']
            else:
                break
        
        for i in range(len(db_instance_list)):
            db_instance_list[i]["RegionId"] = self.region

        return db_instance_list


    def get_local_cluster_list_v1(self, account, region):
        """根据账号和区域查询rds集群列表

        该版本的接口从c3本地查询数据, 这样查询会很快
        """
        output = safe_run_command([
            "c3mc-device-data-get", "curr", "database", "aws-rds-cluster", "account", "区域", "名称", "状态", "实例ID"
        ])

        data = []
        for line in output.split("\n"):
            line = line.strip()
            if line == "":
                continue

            parts = line.split()

            if len(parts) != 5:
                continue

            if parts[0] != account or parts[1] != region:
                continue

            data.append({
                "Name": parts[2],
                "Status": parts[3],
                "Arn": parts[4],
            })

        return sorted(data, key=lambda x: (x['Name'].lower()), reverse=False)

    
    def delete_db_instance(self, db_instance_identifier, skip_final_snapshot=True, final_db_snapshot_identifiel=""):
        """删除rds实例

        Args:
            db_instance_identifier (str): rds实例id
            skip_final_snapshot (bool, optional): 是否跳过最后一个快照. True: 跳过.
            final_db_snapshot_identifiel (str, optional): 最后一个快照的名称. .
        """
        params = {
            "DBInstanceIdentifier": db_instance_identifier,
        }
        if skip_final_snapshot:
            params["SkipFinalSnapshot"] = True
        else:
            params["SkipFinalSnapshot"] = False
            params["FinalDBSnapshotIdentifier"] = final_db_snapshot_identifiel
        
        try:
            self.client.delete_db_instance(
                **params
            )
        except Exception as e:
            if "is already being deleted" not in str(e):
                raise e

        self.wait_until_db_instance_disappear(db_instance_identifier)
        print("成功删除实例: ", db_instance_identifier)
    
    def delete_db_cluster(self, db_cluster_identifier, skip_final_snapshot=True, final_db_snapshot_identifiel=""):
        """回收rds集群

        比如，创建了一个aurora集群，然后删除了所有的实例，这时候需要删除集群，才能回收资源。或者直接调用该接口删除集群

        Args:
            db_cluster_identifier (str): 集群id
        """
        rds_instance_list = self.describe_db_instance_list_of_cluster(db_cluster_identifier)

        # 先删除所有实例
        for rds_instance in rds_instance_list:
            self.delete_db_instance(rds_instance["DBInstanceIdentifier"], skip_final_snapshot, final_db_snapshot_identifiel)

        # 再删除集群
        params = {
            "DBClusterIdentifier": db_cluster_identifier,
        }
        if skip_final_snapshot:
            params["SkipFinalSnapshot"] = True
        else:
            params["SkipFinalSnapshot"] = False
            params["FinalDBSnapshotIdentifier"] = final_db_snapshot_identifiel

        self.client.delete_db_cluster(
            **params
        )
        self.wait_until_db_cluster_disappear(db_cluster_identifier)
        print("成功删除集群: ", db_cluster_identifier)
    
    def wait_until_db_instance_disappear(self, db_instance_identifier, timeout=3600):
        """等待rds实例被删除

        在调用describe_db_instances接口后，实例并不会从控制台马上消失。这里对describe_db_instances接口返回的结果进行轮询，直到实例消失为止。
        Args:
            db_instance_identifier (str): rds实例id
            timeout (int, optional): 超时时间. 单位: 秒。Defaults to 900.
        """
        start = time.time()

        while True:
            if time.time() - start > timeout:
                raise RuntimeError(f"等待rds实例 {db_instance_identifier} 被删除超时")

            db_instance_info = self.describe_db_instances(db_instance_identifier)
            if not db_instance_info:
                return
            else:
                time.sleep(5)


    def wait_until_db_cluster_disappear(self, db_cluster_identifier, timeout=3600):
        """等待rds集群被删除

        在调用 delete_db_cluster 接口后，集群并不会从控制台马上消失。这里对 describe_db_clusters 接口返回的结果进行轮询，直到集群消失为止。
        Args:
            db_cluster_identifier (str): rds集群id
            timeout (int, optional): 超时时间. 单位: 秒。Defaults to 900.
        """
        start = time.time()

        while True:
            if time.time() - start > timeout:
                raise RuntimeError(f"等待rds集群 {db_cluster_identifier} 被删除超时")

            db_cluster_info = self.describe_db_clusters(db_cluster_identifier)
            if not db_cluster_info:
                return
            else:
                time.sleep(5)



