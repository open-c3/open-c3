#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json

import boto3


class Elasticache:
    def __init__(self, access_id, access_key, region):
        self.resource_type = None
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()
        self.page_size = 100

    def create_client(self):
        client = boto3.client(
            "elasticache",
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )
        return client

    def get_instances_from_response(self, response_data):
        data = response_data["CacheClusters"]
        results = []
        for instance in data:
            instance["RegionId"] = self.region
            if instance["Engine"] == self.resource_type:
                results.append(instance)
        return results

    def get_response(self):
        result = []
        res = self.get_data("")
        result.extend(res["data_list"])
        marker = res["marker"]

        while marker != "":
            res = self.get_data(marker)
            result.extend(res["data_list"])
            marker = res["marker"]
        return result

    def get_data(self, marker=""):
        response = self.client.describe_cache_clusters(
            MaxRecords=self.page_size, Marker=marker, ShowCacheNodeInfo=True)
        result = []
        data_list = self.get_instances_from_response(response)
        for instance in data_list:
            try:
                tag_list = self.list_tag(instance["ARN"])
            except Exception as e:
                continue

            instance["Tag"] = tag_list
            result.append(instance)

        res = {
            "marker": "",
            "data_list": result,
        }
        if "Marker" in response:
            res["marker"] = response["Marker"]
        return res

    def list_tag(self, arn):
        response = self.client.list_tags_for_resource(
            ResourceName=arn
        )
        return response["TagList"]

    def list_instances(self, resource_type):
        self.resource_type = resource_type
        return self.get_response()

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
