#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import sys
import threading
import time

from aliyunsdkcore.request import CommonRequest
from aliyunsdkcore.client import AcsClient
from aliyunsdkvpc.request.v20160428.DescribeVpcAttributeRequest import DescribeVpcAttributeRequest
from aliyunsdkvpc.request.v20160428.DescribeVpcsRequest import DescribeVpcsRequest


sys.path.append("/data/Software/mydan/Connector/lib/pp")
from c3mc_utils import retry_network_request


class ThreadSafeArray:
    def __init__(self):
        self._array = []
        self._lock = threading.Lock()

    def append(self, value):
        with self._lock:
            self._array.append(value)


class LibVpc:
    def __init__(self, access_id, access_key, region):
        self.region = region
        self.access_id = access_id
        self.access_key = access_key
        self.client = self.create_client()

    def create_client(self):
        return AcsClient(self.access_id, self.access_key, self.region)
    
    def show_vpc(self, vpc_id):
        request = DescribeVpcAttributeRequest()
        request.set_accept_format('json')
        request.set_VpcId(vpc_id)
        return json.loads(self.client.do_action_with_exception(request))

    def list_vpcs(self):
        """查询区域下的cvm列表
        """
        result = []

        req = DescribeVpcsRequest()
        req.set_accept_format('json')

        for i in range(1, sys.maxsize):
            request = DescribeVpcsRequest()

            request.set_PageNumber(i)
            # 接口支持最大值为50
            request.set_PageSize(50)

            response = retry_network_request(self.client.do_action_with_exception, (request,))

            vpc_list = json.loads(str(response, encoding='utf-8'))["Vpcs"]["Vpc"]

            if len(vpc_list) == 0:
                break
            result.extend(vpc_list)
        return result
    
    def list_tags_for_vpc(self, vpc_id, region_id):
        request = CommonRequest()
        request.set_accept_format('json')
        request.set_domain('vpc.aliyuncs.com')
        request.set_method('POST')
        request.set_protocol_type('https') # https | http
        request.set_version('2016-04-28')
        request.set_action_name('ListTagResources')

        request.add_query_param('ResourceType', "VPC")
        request.add_query_param('ResourceId.1', vpc_id)
        request.add_query_param('RegionId', region_id)

        response = self.client.do_action(request)
        response = json.loads(str(response, encoding = 'utf-8'))
        if "TagResources" in response and "TagResource" in response["TagResources"]:
            return response["TagResources"]["TagResource"]
        return []
        
    
    def list_vpcs_with_tags(self):
        safe_array = ThreadSafeArray()
        max_threads = 5
        threads = []

        def worker(vpc):
            vpc["Tags"] = self.list_tags_for_vpc(vpc["VpcId"], vpc["RegionId"])

            safe_array.append(vpc)

        vpc_list = self.list_vpcs()
        for vpc in vpc_list:
            while threading.active_count() > max_threads: 
                time.sleep(0.1)
            t = threading.Thread(target=worker, args=(vpc,))
            threads.append(t)
            t.start()

        for t in threads:
            t.join()
        
        return vpc_list

