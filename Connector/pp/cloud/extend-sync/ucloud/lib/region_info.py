#!/usr/bin/env /data/Software/mydan/python3/bin/python3
import requests
import json
from ucloud.core import auth

class Region_api():
    
    def __init__(self, public_key, private_key):
        self.public_key = public_key
        self.private_key = private_key
    
    url = 'https://api.ucloud.cn'

    def init_params(self):
        cred = auth.Credential(
            self.public_key,
            self.private_key,
        )
        params = {"Action": "GetRegion"}
        signature = cred.verify_ac(params)
        params["Signature"] = signature
        return params

    def get_region_info(self):
        params = self.init_params()
        region_set = set ()
        try:
            responsed = requests.get(Region_api.url, params=params).json()
            region_list = responsed["Regions"]
            for region in region_list:
                if region["Region"] != "cn-qz":
                    region_set.add(region["Region"])
            return region_set
        except Exception as e:
            print(e)
            raise


