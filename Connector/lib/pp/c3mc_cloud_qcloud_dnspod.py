#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import sys

from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.dnspod.v20210323 import dnspod_client, models


class QcloudDnspod:
    def __init__(self, access_id, access_key):
        self.access_id = access_id
        self.access_key = access_key
        self.client = self.create_client()

    def create_client(self):
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "dnspod.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return dnspod_client.DnspodClient(cred, "", clientProfile)
    
    def describe_domain_list(self):
        """查询域名列表
        """
        result = []
        req = models.DescribeDomainListRequest()
        limit = 3000
        for i in range(sys.maxsize):
            params = {
                "Offset": i * limit,
                "Limit": limit
            }
            req.from_json_string(json.dumps(params))

            resp = self.client.DescribeDomainList(req)

            domain_list = json.loads(resp.to_json_string())["DomainList"]

            if len(domain_list) == 0:
                break
            result.extend(domain_list)
        return result
    
    def describe_record_list(self, domain):
        """查询域名解析列表
        """
        try:
            result = []
            req = models.DescribeRecordListRequest()
            limit = 3000
            for i in range(sys.maxsize):
                params = {
                    "Domain": domain,
                    "Offset": i * limit,
                    "Limit": limit
                }
                req.from_json_string(json.dumps(params))

                resp = self.client.DescribeRecordList(req)

                RecordList = json.loads(resp.to_json_string())["RecordList"]

                if len(RecordList) == 0:
                    break
                result.extend(RecordList)
        except Exception as e:
            if "NoDataOfRecord" in str(e):
                return result

        return result
    
    def get_subdomains(self):
        """获取所有域名的子域名列表
        """
        data = []

        domains = self.describe_domain_list()

        for domain in domains:
            record_list = self.describe_record_list(domain["Name"])

            for record in record_list:
                record["Name"] = record["Name"] + "." + domain["Name"]
                if record["Value"] and record["Value"][-1] == ".":
                    record["Value"] = record["Value"][:-1]
                data.append(record)
        
        return data


    