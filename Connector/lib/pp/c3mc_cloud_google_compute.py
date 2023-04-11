#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import re
import json

from googleapiclient import discovery
from google.oauth2 import service_account



class GoogleCompute:
    def __init__(self, cred_json_path):
        self.cred_json_path = cred_json_path
        self.credentials = self.create_credentials()
        self.service = self.create_service()

    def create_credentials(self):
        return service_account.Credentials.from_service_account_file(self.cred_json_path)
    
    def create_service(self):
        return discovery.build('compute', 'v1', credentials=self.credentials)

    def get_os(self, disk_source):
        if disk_source is None:
            return None

        disk_resp = self.get_disk_info(disk_source)

        if "sourceImage" not in disk_resp:
            return None

        image_resp = self.get_image_info(disk_resp["sourceImage"])

        if 'description' in image_resp:
            return (
                "Windows"
                if image_resp["description"].lower().find("window") != -1
                else "Linux"
            )
        else:
            return "Other"

    def get_disk_info(self, disk_source):
        result = re.search(r'projects/(.*?)/', disk_source)
        project = result[1]

        result = re.search(r'zones/(.*?)/', disk_source)
        zone = result[1]

        result = re.search(r'disks/(.*?)$', disk_source)
        disk = result[1]

        request = self.service.disks().get(project=project, zone=zone, disk=disk)
        return request.execute()

    
    def get_image_info(self, image_source):
        result = re.search(r'projects/(.*?)/', image_source)
        project = result[1]

        image = image_source.split("/")[-1]

        request = self.service.images().get(project=project, image=image)
        return request.execute()

    def get_vm_info(self, zone, instance_name):
        """查询虚拟机详情
        """
        project_id = self.credentials.project_id
        return self.service.instances().get(project=project_id, zone=zone, instance=instance_name).execute()

    def create_vm(self, zone, instance_config):
        """创建虚拟机

        Args:
            zone (string): 可用区
            instance_config (dict): 实例配置字典
        """
        project_id = self.credentials.project_id
        return self.service.instances().insert(project=project_id, zone=zone, body=instance_config).execute()

    def list_regions(self):
        """查询区域详情列表
        """
        data = []
        request = self.service.regions().list(project=self.credentials.project_id)
        while request is not None:
            response = request.execute()

            data.extend(response['items'])

            request = self.service.regions().list_next(previous_request=request, previous_response=response)
        return data

    def list_zones(self):
        """查询可用区详情列表
        """
        data = []
        request = self.service.zones().list(project=self.credentials.project_id, maxResults=500)
        while request is not None:
            response = request.execute()

            data.extend(response['items'])

            request = self.service.zones().list_next(previous_request=request, previous_response=response)
        return sorted(data, key=lambda x: x['name'], reverse=False)

    def list_machine_types(self, zone):
        """查询虚拟机机器类型列表
        """
        data = []
        request = self.service.machineTypes().list(project=self.credentials.project_id, zone=zone, maxResults=500)
        while request is not None:
            response = request.execute()

            data.extend(response['items'])

            request = self.service.machineTypes().list_next(previous_request=request, previous_response=response)
        
        return sorted(data, key=lambda x: x['name'], reverse=False)

    def list_public_images(self):
        """查询公共镜像列表
        """
        data = []
        public_image_project_list = ['centos-cloud', 'debian-cloud', 'rhel-cloud', 'suse-cloud', 'ubuntu-os-cloud', 'windows-cloud']

        for project in public_image_project_list:
            request = self.service.images().list(project=project, fields="items(name,family,selfLink),nextPageToken", maxResults=500)
            while request is not None:
                response = request.execute()
                data.extend(response['items'])
                request = self.service.images().list_next(previous_request=request, previous_response=response)
        return sorted(data, key=lambda x: x['name'], reverse=True)

    def list_custom_images(self):
        """查询谷自定义镜像列表
        """
        data = []

        request = self.service.images().list(project=self.credentials.project_id, fields="items(name,description,family),nextPageToken", maxResults=500)
        while request is not None:
            response = request.execute()
            if not response:
                return data

            data.extend(response['items'])

            request = self.service.images().list_next(previous_request=request, previous_response=response)
        return sorted(data, key=lambda x: x['name'], reverse=True)

    def list_disk_types(self, zone):
        """查询可用的启动磁盘列表。

        创建虚拟机选择启动磁盘时会用到该数据列表
        """
        data = []
        project_id = self.credentials.project_id
        request = self.service.diskTypes().list(project=project_id, zone=zone, maxResults=500)
        while request is not None:
            response = request.execute()
            data.extend(response['items'])
            request = self.service.diskTypes().list_next(previous_request=request, previous_response=response)

        return sorted(data, key=lambda x: x['name'], reverse=False)

    def list_subnetwork(self, region):
        """查询子网列表
        """
        data = []
        project_id = self.credentials.project_id
        request = self.service.subnetworks().list(project=project_id, region=region, maxResults=500)
        while request is not None:
            response = request.execute()
            data.extend(response['items'])
            request = self.service.subnetworks().list_next(previous_request=request, previous_response=response)

        return data

    def list_networks(self):
        """查询网络列表
        """
        data = []
        project_id = self.credentials.project_id
        request = self.service.networks().list(project=project_id, maxResults=500)
        while request is not None:
            response = request.execute()
            data.extend(response['items'])
            request = self.service.networks().list_next(previous_request=request, previous_response=response)

        return data

    def list_elastic_ips(self, region, filter_status=None):
        """查询弹性ip列表

        谷歌云的弹性ip和区域关联, 不能在一个虚拟机上关联其他区域的ip

        Args:
            region (string): 区域
            filter_status (string, optional): ip地址状态，使用该字段过滤ip地址列表。默认返回全部数据。
                可选值: 
                    IN_USE: 表示 IP 地址已经关联了一个资源,比如一个vm
                    RESERVED: 表示 IP 地址目前没有关联任何资源
                    None: 不过滤
        """
        data = []
        project_id = self.credentials.project_id
        request = self.service.addresses().list(project=project_id, region=region)

        while request is not None:
            response = request.execute()
            if 'items' in response:
                data.extend(response['items'])
            request = self.service.addresses().list_next(previous_request=request, previous_response=response)
        
        if filter_status is None:
            return data
        
        return [item for item in data if item["status"] == filter_status]

    def create_elastic_ip(self, region, ip_name):
        """在指定的区域创建弹性 IP 地址"""
        def wait_for_operation(project_id, operation_name):
            print('等待操作结束...')
            while True:
                result = self.service.regionOperations().get(project=project_id, region=region, operation=operation_name).execute()
                if result["status"] == 'DONE':
                    print("操作结束.")
                    break

        project_id = self.credentials.project_id
        ip_body = {
            "name": ip_name,
        }

        request = self.service.addresses().insert(project=project_id, region=region, body=ip_body)
        response = request.execute()
        operation_name = response["name"]

        # 等待操作完成
        wait_for_operation(project_id, operation_name)

        # 获取创建的弹性 IP 地址详细信息
        elastic_ip = self.service.addresses().get(project=project_id, region=region, address=ip_name).execute()
        print(f"区域性弹性 IP 创建成功: {elastic_ip['address']}")
        return elastic_ip['address']
