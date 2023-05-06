#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import boto3
from botocore.config import Config


class AWS_S3:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        config = Config(
            s3={'addressing_style': 'path'},
            region_name=self.region
        )
        client = boto3.client(
            "s3",
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            config=config
        )
        return client

    def list_tag(self, bucket_name):
        try:
            response = self.client.get_bucket_tagging(Bucket=bucket_name)
        except Exception as e:
            if "The TagSet does not exist" in str(e):
                return []
            else: 
                raise RuntimeError(f"获取s3标签出错. bucket_name: {self.bucket_name}") from e
        return response["TagSet"]

    def list_bucket_names(self):
        response = self.client.list_buckets()

        names = [bucket_info["Name"] for bucket_info in response["Buckets"]]
        return sorted(names, reverse=False)
