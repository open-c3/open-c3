#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import sys
import json

import boto3


class LIB_EC2:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        client = boto3.client(
            "ec2",
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )
        return client

    def describe_addresses(self, **kwargs):
        """
        查询弹性ip信息列表
        """
        return self.client.describe_addresses(**kwargs)

    def allocate_address(self):
        """
        分配eip

        返回数据格式为:
        {
            'PublicIp': 'string',
            'AllocationId': 'string',
            'PublicIpv4Pool': 'string',
            'NetworkBorderGroup': 'string',
            'Domain': 'vpc'|'standard',
            'CustomerOwnedIp': 'string',
            'CustomerOwnedIpv4Pool': 'string',
            'CarrierIp': 'string'
        }
        """
        return self.client.allocate_address(Domain="vpc")

    def set_tags_for_eip(self, eip_allocation_id, tags):
        """
        eip关联实例后为eip添加机器的标签

        tags格式为
        [
            {
                'Key': 'string',
                'Value': 'string'
            },
        ]
        """
        return self.client.create_tags(Resources=[eip_allocation_id], Tags=tags)

    def associate_address(self, eip_allocation_id, instance_id):
        """
        将eip和实例关联起来
        """
        return self.client.associate_address(AllocationId=eip_allocation_id, InstanceId=instance_id)


    def describe_instances(self, instance_ids):
        """
        查询ec2实例详情
        """
        return self.client.describe_instances(InstanceIds=instance_ids)

    def disassociate_address(self, association_id):
        """
        解绑eip
        """
        return self.client.disassociate_address(AssociationId=association_id)

    def release_address(self, eip_allocation_id):
        """
        释放eip
        """
        return self.client.release_address(AllocationId=eip_allocation_id)
