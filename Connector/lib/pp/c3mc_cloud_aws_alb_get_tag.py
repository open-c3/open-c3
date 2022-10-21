#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import boto3


class GetTag:
    def __init__(self, access_id, access_key, region, arn_list):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.arn_list = arn_list
        self.client = self.create_client()

    def create_client(self):
        client = boto3.client(
            "elbv2",
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )
        return client

    def list_tag(self):
        arn_tag_dict = {}
        tag_resp = self.client.describe_tags(ResourceArns=self.arn_list)
        for instance_tag in tag_resp["TagDescriptions"]:
            arn_tag_dict[instance_tag["ResourceArn"]] = instance_tag["Tags"]
        return arn_tag_dict
