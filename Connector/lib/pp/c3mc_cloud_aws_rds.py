#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import boto3


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
