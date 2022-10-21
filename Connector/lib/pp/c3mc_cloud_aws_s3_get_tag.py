#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import boto3


class GetTag:
    def __init__(self, access_id, access_key, region, bucket_name):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.bucket_name = bucket_name
        self.client = self.create_client()

    def create_client(self):
        client = boto3.client(
            "s3",
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )
        return client

    def list_tag(self):
        try:
            response = self.client.get_bucket_tagging(
                Bucket=self.bucket_name,
            )
        except Exception as e:
            return []
        return response["TagSet"]
