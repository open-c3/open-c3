#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import boto3
import json


class LibMemoryDB:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        client = boto3.client(
            "memorydb",
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )
        return client

    def list_tag(self, resource_arn):
        """查询资源的标签列表
        """
        return self.client.list_tags(ResourceArn=resource_arn)["TagList"]
    
    def list_clusters(self):
        """查询cluster列表
        """
        cluster_list = []
        next_token = None

        while True:
            if next_token:
                response = self.client.describe_clusters(NextToken=next_token, MaxResults=100, ShowShardDetails=True)
            else:
                response = self.client.describe_clusters(MaxResults=100, ShowShardDetails=True)

            if len(response['Clusters']) > 0:
                for item in response['Clusters']:
                    item["ClusterEndpointAddress"] = item["ClusterEndpoint"]["Address"]
                    item["ClusterEndpointPort"] = item["ClusterEndpoint"]["Port"]
                    item["Tag"] = self.list_tag(item["ARN"])
                    item["Region"] = self.region

                    parts = item["ARN"].split(":")
                    # 组装自定义的资源id (ARN中可能含有"/"符号，导致平台处理出错)
                    # 格式是: 账号id-区域-名称
                    item["CustomResourceId"] = f"{parts[4]}-{parts[3]}-{item['Name']}"

                    cluster_list.append(item)

            # 检查是否有更多分页
            if 'NextToken' in response and response['NextToken']:
                next_token = response['NextToken']
            else:
                break

        return cluster_list
    
    def list_cluster_node(self):
        """

        Returns:
            _type_: _description_
        """
        memorydb_clusters = self.list_clusters()
        data = []

        for cluster in memorydb_clusters:
            for shard in cluster["Shards"]:
                for node in shard["Nodes"]:
                    node["CustomClusterId"] = cluster["CustomResourceId"]
                    node["Region"] = self.region
                    node["ClusterStatus"] = cluster["Status"]
                    node["Tag"] = cluster["Tag"]

                    parts = node["CustomClusterId"].split("-")
                    node["CustomNodeId"] = f"{parts[0]}-{node['Name']}"

                    data.append(node)
        
        return data

