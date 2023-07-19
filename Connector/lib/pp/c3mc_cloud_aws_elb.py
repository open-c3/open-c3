#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import boto3


class LibElb:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        client = boto3.client(
            "elb",
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )
        return client

    def list_tag(self, loadBalancerNames):
        name_tag_dict = {}
        if len(loadBalancerNames) == 0:
            return name_tag_dict
        tag_resp = self.client.describe_tags(
            LoadBalancerNames=loadBalancerNames)
        for instance_tag in tag_resp["TagDescriptions"]:
            name_tag_dict[instance_tag["LoadBalancerName"]
                          ] = instance_tag["Tags"]
        return name_tag_dict
    
    def show_lb_info(self, load_balancer_name):
        """查询elb详情。如果不存在则返回None

        Args:
            load_balancer_name (str): elb名称
        """
        resp = self.client.describe_load_balancers(LoadBalancerNames=[load_balancer_name])
        if 'LoadBalancerDescriptions' not in resp or not len(resp['LoadBalancerDescriptions']):
            return None
        
        return resp['LoadBalancerDescriptions'][0]


    def list_tag_for_load_balancer_name(self, loadBalancerName):
        tag_resp = self.client.describe_tags(
            LoadBalancerNames=[loadBalancerName])
        if len(tag_resp["TagDescriptions"]) == 0:
            return []
        return tag_resp["TagDescriptions"][0]["Tags"]
    
    def list_load_balancers(self):
        """查询lb列表
        """
        load_balancer_list = []
        next_marker = None

        while True:
            if next_marker:
                response = self.client.describe_load_balancers(Marker=next_marker)
            else:
                response = self.client.describe_load_balancers()

            if len(response['LoadBalancerDescriptions']) > 0:
                load_balancer_list.extend(response['LoadBalancerDescriptions'])

            # 检查是否有更多分页
            if 'NextMarker' in response and response['NextMarker']:
                next_marker = response['NextMarker']
            else:
                break

        return load_balancer_list

    def delete_load_balancer(self, load_balancer_name):
        """删除elb

        Args:
            load_balancer_name (str): elb的名称
        """
        self.show_lb_info
        return self.client.delete_load_balancer(
            LoadBalancerName=load_balancer_name
        )
