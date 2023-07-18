#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import boto3


class ELBV2:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
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
        def get_data(next_marker):
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

            d = self.list_tags(arn_list)

            res["data_list"] = data_list
            res["arn_tag_dict"] = d

            if "NextMarker" in response:
                res["next_marker"] = response["NextMarker"]
            return res

        arn_tag_dict = {}
        next_marker = ""
        result = []

        res = get_data("")
        if res["arn_tag_dict"] is not None:
            arn_tag_dict = dict(list(arn_tag_dict.items()) +
                                list(res["arn_tag_dict"].items()))
        result.extend(res["data_list"])
        next_marker = res["next_marker"]

        while next_marker != "":
            res = get_data(next_marker)
            if res["arn_tag_dict"] is not None:
                arn_tag_dict = dict(list(arn_tag_dict.items()) +
                                    list(res["arn_tag_dict"].items()))
            result.extend(res["data_list"])
            next_marker = res["next_marker"]

        for i, s in enumerate(result):
            if s["LoadBalancerArn"] in arn_tag_dict:
                result[i]["Tag"] = arn_tag_dict[s["LoadBalancerArn"]]
        return result

    def list_tags(self, arn_list):
        """查询标签

        Args:
            arn_list (list): arn列表
        """
        tag_resp = self.client.describe_tags(ResourceArns=arn_list)
        return {
            instance_tag["ResourceArn"]: instance_tag["Tags"]
            for instance_tag in tag_resp["TagDescriptions"]
        }

    def get_instance_list(self, resource_type):
        instance_list = self.list_instances()

        return [
            instance
            for instance in instance_list
            if instance["Type"] == resource_type
        ]
