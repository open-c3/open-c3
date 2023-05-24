#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import sys
import json
import time
from botocore.exceptions import ClientError

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

    def stop_instances(self, instance_ids):
        """停止ec2实例

        Args:
            instance_ids (list): 要停止的ec2实例id列表
        """
        return self.client.stop_instances(InstanceIds=instance_ids)

    def start_instances(self, instance_ids):
        """启动ec2实例

        Args:
            instance_ids (list): 要启动的ec2实例id列表
        """
        return self.client.start_instances(InstanceIds=instance_ids)

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

    def describe_instance_status(self):
        """
        查询ec2状态信息列表
        """
        events = []
        next_token = None
        while True:
            if next_token:
                response = self.client.describe_instance_status(IncludeAllInstances=True, NextToken=next_token)
            else:
                response = self.client.describe_instance_status(IncludeAllInstances=True)

            events.extend(response['InstanceStatuses'])

            # 检查是否有更多分页
            if 'NextToken' in response:
                next_token = response['NextToken']
            else:
                break

        return events
    

    def describe_all_instances_of_region(self):
        """
        查询区域下的所有EC2实例，并处理分页查询
        """
        instances = []
        next_token = None

        while True:
            if next_token:
                response = self.client.describe_instances(NextToken=next_token)
            else:
                response = self.client.describe_instances()

            for reservation in response['Reservations']:
                instances.extend(reservation['Instances'])

            # 检查是否有更多分页
            if 'NextToken' in response:
                next_token = response['NextToken']
            else:
                break

        return instances


    def decode_auth_failure_message(self, region, access_key, secret_key, encoded_msg):
        sts = boto3.client('sts',
                        region_name=region,
                        aws_access_key_id=access_key,
                        aws_secret_access_key=secret_key)

        try:
            response = sts.decode_authorization_message(
                EncodedMessage=encoded_msg
            )
            return response['DecodedMessage']
        except ClientError as e:
            print(f"解码错误: {e}")
            return None


    def modify_instance_attribute(self, attribute):
        """修改ec2实例的属性信息

        注意: 在官方api中, attribute字典内包含了InstanceId
        Args:
            attribute (dict): 属性信息。具体的键值请参考
                https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/modify_instance_attribute.html
                该函数不做参数校验，只把参数解包为api接口参数
        """

        try:
            self.client.modify_instance_attribute(**attribute)
        except ClientError as e:
            if e.response['Error']['Code'] == 'UnauthorizedOperation':
                error_msg = e.response['Error']['Message']
                encoded_msg_start = error_msg.find('Encoded authorization failure message: ') + len('Encoded authorization failure message: ')
                encoded_msg = error_msg[encoded_msg_start:]
                decoded_msg = self.decode_auth_failure_message(self.region, self.access_id, self.access_key, encoded_msg)
                print(f"解码的授权失败消息: {decoded_msg}")
            else:
                print(f"ClientError: {e}")
    
    def wait_until_status(self, instance_id, target_status, timeout=600):
        """等待ec2实例进入目标状态

        Args:
            instance_id (string): ec2实例ID
            timeout (int, optional): 超时时间, 单位秒
        """
        start_time = time.time()
        while True:
            instance_info = self.describe_instances([instance_id])["Reservations"][0]["Instances"][0]
            if instance_info["State"]["Name"] == target_status:
                return True
            elif time.time() - start_time > timeout:
                return False
            else:
                time.sleep(5)
