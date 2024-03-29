#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import sys

from aliyunsdkcore.client import AcsClient
from aliyunsdknas.request.v20170626.DescribeRegionsRequest import DescribeRegionsRequest
from aliyunsdknas.request.v20170626.DescribeFileSystemsRequest import DescribeFileSystemsRequest


sys.path.append("/data/Software/mydan/Connector/lib/pp")
from c3mc_utils import sleep_time_for_limiting, bytes_to_gb

max_times_describe_file_systems = 20


class LibAliyunFS:
    def __init__(self, access_id, access_key, region):
        self.region = region
        self.access_id = access_id
        self.access_key = access_key
        self.client = self.create_client()

    def create_client(self):
        return AcsClient(self.access_id, self.access_key, self.region)
    
    def describe_file_systems(self):
        """查询文件系统列表
        """
        result = []

        req = DescribeFileSystemsRequest()
        req.set_accept_format('json')

        number = 100
        for i in range(1, sys.maxsize):
            request = DescribeFileSystemsRequest()

            request.set_PageNumber(i)
            request.set_PageSize(number)

            response = self.client.do_action_with_exception(request)

            file_system_list = json.loads(str(response, encoding='utf-8'))["FileSystems"]["FileSystem"]

            for item in file_system_list:
                if "Tags" in item and not isinstance(item["Tags"], list):
                    if "Tag" in item["Tags"] and isinstance(item["Tags"]["Tag"], list):
                        item["Tags"] = item["Tags"]["Tag"]

                if "MeteredIASize" in item:
                    item["MeteredIASize"] = int(bytes_to_gb(item["MeteredIASize"]))

                item["Capacity"] = int(bytes_to_gb(item["Capacity"]))
                item["MeteredSize"] = int(bytes_to_gb(item["MeteredSize"]))
            
                result.append(item)

            if len(file_system_list) < number:
                break

            sleep_time_for_limiting(max_times_describe_file_systems)

        return result
    
    def describe_regions(self):
        """查询支持的区域列表
        """
        result = []

        req = DescribeRegionsRequest()
        req.set_accept_format('json')

        number = 100
        for i in range(1, sys.maxsize):
            request = DescribeRegionsRequest()

            request.set_PageNumber(i)
            request.set_PageSize(number)

            response = self.client.do_action_with_exception(request)
            response = json.loads(response.decode('utf-8'))

            result.extend(response["Regions"]["Region"])

            if len(response["Regions"]["Region"]) < number:
                break

        return result 
    
    def describe_region_list(self):
        region_list = self.describe_regions()
        return [item["RegionId"] for item in region_list]
