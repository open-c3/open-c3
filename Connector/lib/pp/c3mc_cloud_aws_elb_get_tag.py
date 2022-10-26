#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import boto3


class GetTag:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        client = boto3.client(
            "elb",
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )
        return client

    def list_tag(self, loadBalancerNames):
        name_tag_dict = {}
        if len(loadBalancerNames) == 0:
            return name_tag_dict
        tag_resp = self.client.describe_tags(
            LoadBalancerNames=loadBalancerNames)
        for instance_tag in tag_resp["TagDescriptions"]:
            name_tag_dict[instance_tag["LoadBalancerName"]
                          ] = instance_tag["Tags"]
        return name_tag_dict

    def list_tag_for_loadBalancerName(self, loadBalancerName):
        tag_resp = self.client.describe_tags(
            LoadBalancerNames=[loadBalancerName])
        if len(tag_resp["TagDescriptions"]) == 0:
            return []
        return tag_resp["TagDescriptions"][0]["Tags"]
