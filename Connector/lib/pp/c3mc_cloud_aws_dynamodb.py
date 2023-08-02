#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import boto3


class LibAwsDynamodb:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        client = boto3.client(
            "dynamodb",
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )
        return client

    def list_tag(self, resource_arn):
        """查询标签列表

        resource_arn(string): 资源arn
        """
        tag_list = []
        response = self.client.list_tags_of_resource(ResourceArn=resource_arn)
        tag_list.extend(response["Tags"])
        while "NextToken" in response:
            response = self.client.list_tags_of_resource(
                ResourceArn=resource_arn,
                NextToken=response["NextToken"]
            )
            tag_list.extend(response["Tags"])
        return tag_list

    def add_tags(self, arn, tag_list):
        """给实例添加一个或多个标签

        Args:
            arn: 资源arn
            tag_list (list): 要添加的标签列表。格式为 [{"Key": "key1", "Value": "value1"}, {"Key": "key2", "Value": "value2"}]
        """
        return self.client.tag_resource(
            ResourceArn=arn,
            Tags=tag_list
        )

    def remove_tags(self, arn, need_delete_list):
        """给实例删除一个或多个标签

        Args:
            arn: 资源arn
            need_delete_list (list): 要删除的标签key列表。格式为 ["key1", "key2"]
        """
        return self.client.untag_resource(
            ResourceArn=arn,
            TagKeys=need_delete_list
        )
