#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json

from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkecs.v2.region.ecs_region import EcsRegion
from huaweicloudsdkecs.v2 import *


class Flavors:
    def __init__(self, access_id, access_key, project_id, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        if project_id == None:
            self.project_id = None
        else:
            self.project_id = project_id.strip()
        self.client = self.create_client()

    def create_client(self):
        credentials = BasicCredentials(self.access_id, self.access_key, self.project_id)

        return EcsClient.new_builder() \
        .with_credentials(credentials) \
        .with_region(EcsRegion.value_of(self.region)) \
        .build()

    def list_flavors(self):
        request = ListFlavorsRequest()
        response = self.client.list_flavors(request)
        return json.loads(str(response))["flavors"]
