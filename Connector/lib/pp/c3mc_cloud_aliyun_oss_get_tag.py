#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import oss2


class GetTag:
    def __init__(self, access_id, access_key, location, bucket_name):
        self.access_id = access_id
        self.access_key = access_key
        self.location = location
        self.bucket_name = bucket_name
        self.client = self.create_client()

    def create_client(self):
        endpoint = 'https://{}.aliyuncs.com'.format(self.location)
        auth = oss2.Auth(self.access_id, self.access_key)
        return oss2.Bucket(auth, endpoint, self.bucket_name)

    def list_tag(self):
        tag_list = []
        result = self.client.get_bucket_tagging()
        tag_rule = result.tag_set.tagging_rule

        for key, value in tag_rule.items():
            tag_list.append({
                "key": key,
                "value": value
            })
        return tag_list
