#!/usr/bin/env python2
# -*- coding: utf-8 -*-

import json
from kscore.session import get_session


class KsyunTag:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.page_size = 50
        self.client = self.create_client()

    def create_client(self):
        s = get_session()
        client = s.create_client(
            "tag", ks_access_key_id=self.access_id, ks_secret_access_key=self.access_key, region_name=self.region)
        return client

    def get_tag_dict(self):
        tag_list = []
        response = self.client.describe_tags(MaxResults=self.page_size)
        tag_list.extend(response["TagSet"])
        while "NextToken" in response:
            response = self.client.describe_tags(
                MaxResults=self.page_size, NextToken=response["NextToken"])
            tag_list.extend(response["TagSet"])

        tag_dict = {}
        for tag in tag_list:
            resource_id = tag["ResourceId"]

            if resource_id not in tag_dict:
                tag_dict[resource_id] = []
            tag_dict[resource_id].append(tag)
        return tag_dict
