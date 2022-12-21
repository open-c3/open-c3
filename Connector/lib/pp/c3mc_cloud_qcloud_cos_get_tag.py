#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

from qcloud_cos import CosConfig
from qcloud_cos import CosS3Client


class GetTag:
    def __init__(self, access_id, access_key, region, bucket_name):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.bucket_name = bucket_name
        self.client = self.create_client()

    def create_client(self):
        config = CosConfig(Region=self.region, SecretId=self.access_id,
                           SecretKey=self.access_key)  # 获取配置对象
        client = CosS3Client(config)
        return client

    def list_tag(self):
        try:
            response = self.client.get_bucket_tagging(
                Bucket=self.bucket_name
            )
            if "TagSet" in response:
                return response["TagSet"]["Tag"]
            return []
        except:
            return []
