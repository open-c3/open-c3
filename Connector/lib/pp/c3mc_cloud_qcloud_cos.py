#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import sys

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
    
    def delete_all_tag(self, bucket_name):
        """删除存储桶的所有标签
        """
        return self.client.delete_bucket_tagging(
            Bucket=bucket_name
        )
    
    def tag_delete(self, bucket_name, region, delete_key_list):
        """删除指定标签

        Args:
            region: (str): 存储桶所在区域
            bucket_name (str): 存储桶名称
            delete_key_list (list): 要删除的标签key列表
        """
        tag_list = self.list_tag(bucket_name, region)
        print(f"tag_delete. bucket_name: {bucket_name}, all_tag: {json.dumps(tag_list)}, delete_key_list: {json.dumps(delete_key_list)}", file=sys.stderr)

        need_keep_tag_list = [
            {"key": item["Key"], "value": item["Value"]}
            for item in tag_list
            if item["Key"] not in delete_key_list
        ]
        self.delete_all_tag(bucket_name)
        if need_keep_tag_list:
            self.tag_add(bucket_name, need_keep_tag_list)

