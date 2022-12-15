#!/usr/bin/env python2
# -*- coding: utf-8 -*-

import json
from kscore.session import get_session


class Vpc:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        s = get_session()
        client = s.create_client(
            "vpc", ks_access_key_id=self.access_id, ks_secret_access_key=self.access_key, region_name=self.region)
        return client

    def show_vpc(self, vpc_id):
        response = self.client.describe_vpcs(**{'VpcId.1': vpc_id})
        return response["VpcSet"][0]


