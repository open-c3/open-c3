#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import boto3


class GetTag:
    def __init__(self, access_id, access_key, region, arn):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.arn = arn
        self.client = self.create_client()

    def create_client(self):
        client = boto3.client(
            "dynamodb",
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )
        return client

    def list_tag(self):
        tag_list = []
        response = self.client.list_tags_of_resource(ResourceArn=self.arn)
        tag_list.extend(response["Tags"])
        while "NextToken" in response:
            response = self.client.list_tags_of_resource(
                ResourceArn=self.arn,
                NextToken=response["NextToken"]
            )
            tag_list.extend(response["Tags"])
        return tag_list
