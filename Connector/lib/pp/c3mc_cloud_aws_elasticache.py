#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json

import boto3


class Elasticache:
    def __init__(self, resource_type, access_id, access_key, region):
        # resource_type可以取值 memcached 或者 redis
        self.resource_type = resource_type
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()
        self.page_size = 25

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
                tag_list = self.list_tag(
                    self.resource_type, self.access_id, self.access_key, self.region, instance["ARN"])
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

    def list_tag(self, resource_type, access_id, access_key, region, arn):
        from c3mc_cloud_aws_elasticache_get_tag import GetTag
        return GetTag(resource_type, access_id, access_key, region, arn).list_tag()

    def show(self):
        instance_list = self.get_response()
        for instance in instance_list:
            print(json.dumps(instance, default=str))
