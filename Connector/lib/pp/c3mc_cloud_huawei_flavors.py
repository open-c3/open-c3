#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkecs.v2.region.ecs_region import EcsRegion
from huaweicloudsdkecs.v2 import *
from huaweicloudsdkcore.exceptions import exceptions

class Flavors:
    def __init__(self, access_id, access_key, project_id, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.project_id = project_id.strip() if project_id not in [None, "None"] else None
        self.client = self.create_client()

    def create_client(self):
        try:
            credentials = BasicCredentials(self.access_id, self.access_key, self.project_id)
            return EcsClient.new_builder() \
                .with_credentials(credentials) \
                .with_region(EcsRegion.value_of(self.region)) \
                .build()
        except exceptions.ClientRequestException as e:
            print(f"Warning: Error creating client: {e}")
            return None

    def list_flavors(self):
        if self.client is None:
            print("Warning: Client not initialized. Skipping flavor list.")
            return []

        try:
            request = ListFlavorsRequest()
            response = self.client.list_flavors(request)
            return json.loads(str(response))["flavors"]
        except exceptions.ClientRequestException as e:
            print(f"Warning: Error listing flavors: {e}")
            if e.error_code == "APIGW.0802":
                print("The IAM user does not have permission in this region. Skipping flavor list.")
            return []
