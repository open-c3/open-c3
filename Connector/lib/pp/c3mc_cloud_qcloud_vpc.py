#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import sys

from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.vpc.v20170312 import vpc_client, models

sys.path.append("/data/Software/mydan/Connector/lib/pp")
from c3mc_utils import sleep_time_for_limiting

max_times_describe_vpcs = 100


class QcloudVpc:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "vpc.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return vpc_client.VpcClient(cred, self.region, clientProfile)

    def show_vpc(self, vpc_id):
        req = models.DescribeVpcsRequest()
        params = {
            "VpcIds": [ vpc_id ]
        }
        req.from_json_string(json.dumps(params))
        resp = self.client.DescribeVpcs(req)
        return json.loads(resp.to_json_string())["VpcSet"][0]

    def show_vpcs_dict(self, vpc_ids):
        req = models.DescribeVpcsRequest()
        params = {
            "VpcIds": vpc_ids
        }
        req.from_json_string(json.dumps(params))
        resp = self.client.DescribeVpcs(req)

        return {
            vpc["VpcId"]: vpc
            for vpc in json.loads(resp.to_json_string())["VpcSet"]
        }
    
    def list_vpcs(self):
        """查询区域下vpc列表
        """
        result = []
        req = models.DescribeVpcsRequest()
        for i in range(1, sys.maxsize):
            params = {
                "Limit": "100",
                "Offset": str((i - 1) * 100)
            }
            req.from_json_string(json.dumps(params))

            resp = self.client.DescribeVpcs(req)

            vpc_list = json.loads(resp.to_json_string())["VpcSet"]

            if len(vpc_list) == 0:
                break
            result.extend(vpc_list)
            sleep_time_for_limiting(max_times_describe_vpcs)
        return result

    def list_subnets_of_vpc(self, vpcId, zone=None):
        """查询区域下subnet列表
        """
        result = []
        req = models.DescribeSubnetsRequest()
        for i in range(1, sys.maxsize):
            params = {
                "Filters": [
                    {
                        "Name": "vpc-id",
                        "Values": [ vpcId ]
                    }
                ],
                "Limit": "100",
                "Offset": str((i - 1) * 100)
            }
            if zone is not None:
                params["Filters"].append({
                    "Name": "zone",
                    "Values": [ zone ]
                })
            req.from_json_string(json.dumps(params))

            resp = self.client.DescribeSubnets(req)

            subnet_list = json.loads(resp.to_json_string())["SubnetSet"]

            if len(subnet_list) == 0:
                break
            result.extend(subnet_list)

            sleep_time_for_limiting(max_times_describe_vpcs)
        return result
