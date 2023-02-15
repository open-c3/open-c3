#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import sys
import json

import boto3


class ELBV2:
    def __init__(self, access_id, access_key, region, resource_type):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.resource_type = resource_type
        self.client = self.create_client()
        # 查询标签时，为了提高速度，使用了批量查询
        # 但是批量查询一次最多只能查20个，所以这里使用了
        # 较小的每页数目
        self.page_size = 20

    def create_client(self):
        client = boto3.client(
            "elbv2",
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )
        return client

    def get_instances_from_response(self, response_data):
        return response_data["LoadBalancers"]

    def list_instances(self):
        arn_tag_dict = {}
        next_marker = ""
        result = []

        res = self.get_data("")
        if res["arn_tag_dict"] is not None:
            arn_tag_dict = dict(list(arn_tag_dict.items()) +
                                list(res["arn_tag_dict"].items()))
        result.extend(res["data_list"])
        next_marker = res["next_marker"]

        while next_marker != "":
            res = self.get_data(next_marker)
            if res["arn_tag_dict"] is not None:
                arn_tag_dict = dict(list(arn_tag_dict.items()) +
                                    list(res["arn_tag_dict"].items()))
            result.extend(res["data_list"])
            next_marker = res["next_marker"]

        for i, s in enumerate(result):
            if s["LoadBalancerArn"] in arn_tag_dict:
                result[i]["Tag"] = arn_tag_dict[s["LoadBalancerArn"]]
        return result

    def get_data(self, next_marker):
        res = {
            "next_marker": "",
            "data_list": [],
            "arn_tag_dict": {}
        }
        response = self.client.describe_load_balancers(
            PageSize=self.page_size, Marker=next_marker)
        arn_list = []
        data_list = self.get_instances_from_response(response)
        if len(data_list) == 0:
            return res

        for instance in data_list:
            arn_list.append(instance["LoadBalancerArn"])

        d = self.list_tag(
            self.access_id, self.access_key, self.region, arn_list)

        res["data_list"] = data_list
        res["arn_tag_dict"] = d

        if "NextMarker" in response:
            res["next_marker"] = response["NextMarker"]
        return res

    def list_tag(self, access_id, access_key, region, arn_list):
        sys.path.append("/data/Software/mydan/Connector/lib/pp")
        from c3mc_cloud_aws_alb_get_tag import GetTag
        return GetTag(access_id, access_key, region).list_tag(arn_list)

    def get_instance_list(self):
        instance_list = self.list_instances()

        result = []
        for instance in instance_list:
            if instance["Type"] == self.resource_type:
                result.append(instance)
        return result
