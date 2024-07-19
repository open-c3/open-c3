#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-
import sys
import time
import json
import boto3

class GlobalAccelerator(object):
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()
        self.page_size = 100

    def create_client(self):

        client = boto3.client(
            "globalaccelerator",
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )

        return client

    def add_tags(self, accelerator_arn, tag_list):
        """给加速器添加一个或多个标签

        Args:
            accelerator_arn: 加速器的ARN
            tag_list (list): 要添加的标签列表。格式为 [{"Key": "key1", "Value": "value1"}, {"Key": "key2", "Value": "value2"}]
        """
        return self.client.tag_resource(
            ResourceArn=accelerator_arn,
            Tags=tag_list
        )

    def remove_tags(self, accelerator_arn, need_delete_list):
        """给加速器删除一个或多个标签

        Args:
            accelerator_arn: 加速器的ARN
            need_delete_list (list): 要删除的标签key列表。格式为 ["key1", "key2"]
        """
        return self.client.untag_resource(
            ResourceArn=accelerator_arn,
            TagKeys=need_delete_list
        )

    def get_accelerators_list(self):
        """获取所有Global Accelerator的列表"""
        accelerators = []
        next_token = None

        while True:
            if next_token:
                response = self.client.list_accelerators(MaxResults=self.page_size, NextToken=next_token)
            else:
                response = self.client.list_accelerators(MaxResults=self.page_size)

            accelerators.extend(response['Accelerators'])

            if 'NextToken' in response:
                next_token = response['NextToken']
            else:
                break

        return sorted(accelerators, key=lambda x: (x['Name'].lower()), reverse=False)
