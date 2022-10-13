#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json

import boto3
import botocore


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
            instance["RegionId"] = instance["PreferredAvailabilityZone"][:-1]
            if instance["Engine"] == self.resource_type:
                results.append(instance)
        return results

    def get_response(self):
        response = self.client.describe_cache_clusters(
            MaxRecords=self.page_size)
        results = self.get_instances_from_response(response)
        while "Marker" in response:
            response = self.client.describe_cache_clusters(
                MaxRecords=self.page_size, Marker=response["Marker"])
            data_list = self.get_instances_from_response(response)
            for instance in data_list:
                try:
                    tag_resp = self.list_tag(instance["ARN"])
                except:
                    continue

                instance["Tag"] = tag_resp["TagList"]
                results.append(instance)
        return results

    def list_tag(self, arn):
        return self.client.list_tags_for_resource(
            ResourceName=arn
        )

    def show(self):
        instance_list = self.get_response()
        for instance in instance_list:
            print(json.dumps(instance, default=str))
