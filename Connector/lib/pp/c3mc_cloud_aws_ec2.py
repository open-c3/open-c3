#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import time
import sys

import boto3
from botocore.exceptions import ClientError


sys.path.append("/data/Software/mydan/Connector/lib/pp")
from c3mc_utils import safe_run_command


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

    def describe_instance_with_tries(self, instance_id, max_tries=50, every_wait_time=5):
        """查询ec2实例详情。如果查询失败会重试

        Args:
            instance_id (str): ec2实例id
            max_tries (int, optional): 最大重试次数. Defaults to 50.
            every_wait_time (int, optional): 每次重试前的等待时间, 单位秒. Defaults to 5.
        """
        fail_times = 0

        while True:
            if fail_times > max_tries:
                raise RuntimeError(f"查询ec2实例信息失败, instance_id: {instance_id}, max_tries: {max_tries}, every_wait_time: {every_wait_time}")
            
            if not self.describe_instances([instance_id])["Reservations"][0]["Instances"]:
                fail_times += 1
                time.sleep(every_wait_time)
                continue

            return self.describe_instances([instance_id])["Reservations"][0]["Instances"][0]
            

    def stop_instances(self, instance_ids):
        """停止ec2实例

        Args:
            instance_ids (list): 要停止的ec2实例id列表
        """
        return self.client.stop_instances(InstanceIds=instance_ids, Force=True)

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

    def terminate_instances(self, instance_ids):
        """删除ec2实例列表。注意该方法只删除ec2实例本身, 关联的eip和磁盘并不一定删除(磁盘是否自动删除取决于是否配置了删除ec2时自动删除磁盘)

        Args:
            instance_ids (list): ec2实例id列表
        """
        return self.client.terminate_instances(InstanceIds=instance_ids)

    def run_instances(self, request):
        """
        创建ec2实例
        """
        while True:
            try:
                return self.client.run_instances(**request)
            except Exception as e:
                if "We currently do not have sufficient" in str(e):
                    time.sleep(5)
                    continue

    def describe_volumes_by_instance_id(self, instance_id):
        response = self.client.describe_volumes(Filters=[{'Name': 'attachment.instance-id', 'Values': [instance_id]}])
        return response['Volumes']

    def describe_volumes_by_volume_id(self, volume_id):
        response = self.client.describe_volumes(VolumeIds=[volume_id])
        return response['Volumes']

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
                encoded_msg_start = error_msg.find('Encoded authorization failure message: ') + len(
                    'Encoded authorization failure message: ')
                encoded_msg = error_msg[encoded_msg_start:]
                decoded_msg = self.decode_auth_failure_message(self.region, self.access_id, self.access_key,
                                                               encoded_msg)
                print(f"解码的授权失败消息: {decoded_msg}")
            else:
                print(f"ClientError: {e}")

    def wait_ec2_until_status(self, instance_id, target_status, timeout=600):
        """等待ec2实例进入目标状态

        Args:
            instance_id (string): ec2实例ID
            target_status: (string)。ec2的目标状态。可选值为: pending | running | shutting-down | terminated | stopping | stopped
            timeout (int, optional): 超时时间, 单位秒
        """
        error_str = ""

        start_time = time.time()
        while True:
            print(
                f"等待实例处于 {target_status} 状态, instance_id: {instance_id}, region: {self.region}, 超时时间: {timeout}")

            try:
                instance_info = self.describe_instances([instance_id])["Reservations"][0]["Instances"][0]
            except ClientError as e:
                if "does not exist" in e:
                    # 刚创建完ec2后查询资源似乎有时候查不到
                    continue
                raise RuntimeError("查询ec2实例信息时出现异常") from e

            if instance_info["State"]["Name"] == target_status:
                return
            elif time.time() - start_time > timeout:
                if error_str:
                    raise RuntimeError(error_str)

                raise RuntimeError(
                    f"等待实例处于 {target_status} 状态, instance_id: {instance_id}, 出现超时错误, timeout: {timeout}")
            else:
                time.sleep(5)

    def wait_volume_until_status(self, volume_id, target_status, timeout=600):
        """等待ebs volume实例进入目标状态

        Args:
            volume_id (string): volume ID
            target_status: (string)。volume的目标状态。可选值为: creating | available | in-use | deleting | deleted | error
            timeout (int, optional): 超时时间, 单位秒
        """
        start_time = time.time()
        while True:
            print(f"等待volume处于 {target_status} 状态, volume_id: {volume_id}")
            volume_info = self.describe_volumes_by_volume_id(volume_id)[0]
            if volume_info["State"] == target_status:
                return True
            elif time.time() - start_time > timeout:
                return False
            else:
                time.sleep(5)

    def allocate_address(self, number, tags=None):
        """创建指定个数的eip(用于后续绑定eip)

        Args:
            number (num): 创建eip的个数
        """
        allocation_ids = []

        for _ in range(number):
            response = self.client.allocate_address()
            # eip的唯一标识符。请注意，AllocationId仅适用于VPC中的弹性IP地址
            allocation_id = response["AllocationId"]

            # 为eip添加ec2的标签
            if tags:
                response = self.set_tags_for_eip(allocation_id, tags)
                print(f"为eip添加标签, allocationId: {allocation_id}, 结果: {json.dumps(response)}")

            allocation_ids.append(allocation_id)

        return allocation_ids

    def bind_eip_to_ec2(self, instance_ids, allocation_ids):
        """给ec2绑定eip。instance_ids的长度和allocation_ids必须相等

        Args:
            instance_ids (list): ec2 id列表
            tags (list, optional): 要给eip绑定的标签列表(这里标签列表一般使用ec2的标签列表)。
        """
        if len(instance_ids) != len(allocation_ids):
            raise RuntimeError(
                f"传入的实例id数目和要绑定的eip的数目不等, instance_ids: {instance_ids}, allocation_ids: {allocation_ids}")

        for index, instance_id in enumerate(instance_ids):
            allocation_id = allocation_ids[index]

            # 等待实例状态正常，否则绑定eip出错
            self.wait_ec2_until_status(instance_id, "running", 600)

            # eip绑定ec2实例
            response = self.associate_address(allocation_id, instance_id)
            print(
                f"绑定eip和ec2, instance_id: {instance_id}, allocationId: {allocation_id}, 结果: {json.dumps(response)}")

    def copy_tags_of_instance_to_volume(self, instance_ids):
        """将ec2的标签都打在关联的所有volume上

        Args:
            instance_ids (list): ec2实例id列表
        """
        for instance_id in instance_ids:
            instance_info = self.describe_instance_with_tries(instance_id)
            tags = instance_info['Tags']

            volumes = self.describe_volumes_by_instance_id(instance_id)

            for volume in volumes:
                volume_id = volume['VolumeId']
                res = self.client.create_tags(Resources=[volume_id], Tags=tags)
                print(f"对volume打标签. instance_id: {instance_id}, volume_id: {volume_id}, 结果: {json.dumps(res)}")

    def release_address_of_ec2(self, instance_ids):
        """释放ec2实例的弹性ip列表

        Args:
            instance_ids (list): ec2实例id列表
        """
        for instance_id in instance_ids:
            eip_info_list = self.describe_addresses(
                Filters=[
                    {
                        "Name": "instance-id",
                        "Values": [
                            instance_id,
                        ],
                    }
                ]
            )["Addresses"]
            for eip_info in eip_info_list:
                print(f"准备释放ec2实例的eip, instance_id: {instance_id}, public_ip: {eip_info['PublicIp']}")
                # 先解绑eip再释放eip
                self.disassociate_address(eip_info["AssociationId"])
                self.release_address(eip_info["AllocationId"])

    def delete_volumes_of_ec2(self, instance_ids):
        def is_root_volume(volume):
            for attachment in volume['Attachments']:
                if attachment['Device'] in ['/dev/sda1', '/dev/xvda']:
                    return True
            return False

        for instance_id in instance_ids:
            volumes = self.describe_volumes_by_instance_id(instance_id)

            for volume in volumes:
                if is_root_volume(volume):
                    # 跳过root volume
                    continue
                volume_id = volume["VolumeId"]
                print(f"准备删除ec2实例的volume, instance_id: {instance_id}, volume_id: {volume_id}")
                self.client.detach_volume(
                    InstanceId=instance_id,
                    VolumeId=volume_id,
                )
                timeout = 600
                if not self.wait_volume_until_status(volume_id, "available", timeout):
                    raise RuntimeError(
                        f"等待volume处于 available 状态超时, volume_id: {volume_id}, 超时时间: {timeout} 秒")
                self.client.delete_volume(VolumeId=volume_id)

    def delete_ec2(self, instance_ids):
        """回收ec2。这是一个比较高级的实现, 内部封装了回收ec2关联资源的逻辑

        Args:
            instance_ids (list): ec2 id列表
        """
        # 过滤掉已经被删除的实例
        filtered_instance_ids = []

        for instance_id in instance_ids:
            instance_list = self.describe_instances([instance_id])["Reservations"][0]["Instances"]
            if not instance_list:
                continue
            print(f"ec2_info: {json.dumps(instance_list[0], default=str)}")
            if instance_list[0]["State"]["Name"] == "terminated":
                print(f"实例 {instance_list[0]['InstanceId']} 已经被删除，跳过删除操作 ")
                continue

            filtered_instance_ids.append(instance_list[0]["InstanceId"])
        
        if not filtered_instance_ids:
            return

        self.stop_instances(filtered_instance_ids)

        for instance_id in filtered_instance_ids:
            self.wait_ec2_until_status(instance_id, "stopped", 900)

        self.release_address_of_ec2(filtered_instance_ids)
        # 目前c3创建ec2默认开启了删除ec2时自动删除数据盘
        # 这里显式的删除数据盘是为了防止有人在其他地方开ec2在这里回收
        self.delete_volumes_of_ec2(filtered_instance_ids)
        self.terminate_instances(filtered_instance_ids)

    def add_tags(self, instance_id, tag_list):
        """给实例添加一个或多个标签

        Args:
            instance_id (str): 实例id
            tag_list (list): 要添加的标签列表。格式为 [{"Key": "key1", "Value": "value1"}, {"Key": "key2", "Value": "value2"}]
        """
        return self.client.create_tags(
            Resources=[instance_id],
            Tags=tag_list
        )

    def remove_tags(self, instance_id, tag_list):
        """给实例添加一个或多个标签

        Args:
            instance_id (str): 实例id
            tag_list (list): 要删除的标签列表。格式为 [{"Key": "key1", "Value": "value1"}, {"Key": "key2", "Value": "value2"}]
        """
        return self.client.delete_tags(
            Resources=[instance_id],
            Tags=tag_list
        )

    def get_local_instance_list_v1(self, account, region):
        """根据账号和区域查询ec2列表

        该版本的接口从c3本地查询数据, 这样查询会很快
        """
        output = safe_run_command(["c3mc-device-data-get", "curr", "compute", "aws-ec2", "account", "区域", "实例ID", "内网IP", "Architecture", "实例类型"])

        data = []
        for line in output.split("\n"):
            line = line.strip()
            if line == "":
                continue

            parts = line.split()

            if len(parts) != 6:
                continue

            if parts[0] != account or parts[1] != region:
                continue

            data.append({
                "InstanceId": parts[2],
                "PrivateIpAddress": parts[3],
                "Architecture": parts[4],
                "InstanceType": parts[5],
            })

        return sorted(data, key=lambda x: (x['InstanceId'].lower()), reverse=False)
