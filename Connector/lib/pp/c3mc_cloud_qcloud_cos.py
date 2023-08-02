#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-
from qcloud_cos import CosConfig
from qcloud_cos import CosS3Client


class QcloudCos:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        service_domain = f'cos.{self.region}.myqcloud.com'
        config = CosConfig(Region=self.region, SecretId=self.access_id,
                           SecretKey=self.access_key, ServiceDomain=service_domain)
        return CosS3Client(config)

    def list_tag(self, bucket_name, region=None):
        if region and region != self.region:
            self.region = region
            self.client = self.create_client()

        try:
            response = self.client.get_bucket_tagging(
                Bucket=bucket_name
            )
            return response["TagSet"]["Tag"] if "TagSet" in response else []
        except Exception as e:
            if "NoSuchTagSet" not in str(e):
                raise e
            return []
    
    def tag_add(self, bucket_name, tag_list):
        """添加标签

        Args:
            bucket_name (str): 存储桶名称
            tag_list (list): 标签列表，格式为 [{"key": "key1", "value": "value1"}]
        """
        current_tags = self.list_tag(bucket_name)

        m = {tag["Key"]: tag["Value"] for tag in current_tags}
        for tag in tag_list:
            m[tag["key"]] = tag["value"]

        self.client.put_bucket_tagging(
            Bucket=bucket_name,
            Tagging={
                'TagSet': {
                    'Tag': [{"Key": key, "Value": value} for key, value in m.items()]
                }
            }
        )

