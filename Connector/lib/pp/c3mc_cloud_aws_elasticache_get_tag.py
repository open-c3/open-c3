#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import boto3
import json


class GetTag:
    def __init__(self, resource_type, access_id, access_key, region, arn):
        # resource_type可以取值 memcached 或者 redis
        self.resource_type = resource_type
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.arn = arn
        self.client = self.create_client()

    def create_client(self):
        client = boto3.client(
            "elasticache",
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )
        return client

    def list_tag(self):
        response = self.client.list_tags_for_resource(
            ResourceName=self.arn
        )
        return response["TagList"]
