#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-


import oss2
from oss2.models import Tagging, TaggingRule


class LibAliyunOss:
    def __init__(self, access_id, access_key, location, bucket_name):
        self.access_id = access_id
        self.access_key = access_key
        self.location = location
        self.bucket_name = bucket_name
        self.bucket = self.create_client()

    def create_client(self):
        endpoint = f'https://{self.location}.aliyuncs.com'
        auth = oss2.Auth(self.access_id, self.access_key)
        return oss2.Bucket(auth, endpoint, self.bucket_name)

    def list_tag(self):
        result = self.bucket.get_bucket_tagging()
        tag_rule = result.tag_set.tagging_rule

        return [{"key": key, "value": value} for key, value in tag_rule.items()]

    def update_tags(self, curr_tag_list):
        """给实例更新标签

        如果curr_tag_list列表为空，则为清空存储桶的标签

        Args:
            curr_tag_list (list): 当前标签列表，使用覆盖的方式更新标签列表。
                                格式为 [{"key": "key1", "value": "value1"}, {"key": "key2", "value": "value2"}]
        """
        rule = TaggingRule()
        for tag in curr_tag_list:
            rule.add(tag["key"], tag["value"])

        tagging = Tagging(rule)

        # 更新标签的时候
        # 如果标签不为空，则需要调用put_bucket_tagging覆盖标签
        # 如果标签为空，则调用delete_bucket_tagging删除桶的标签
        if len(curr_tag_list):
            self.bucket.put_bucket_tagging(tagging)
        else:
            self.bucket.delete_bucket_tagging()
