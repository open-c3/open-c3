#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import re
import time

from googleapiclient import discovery
from google.oauth2 import service_account
from googleapiclient.errors import HttpError



class GoogleCompute:
    def __init__(self, cred_json_path):
        self.cred_json_path = cred_json_path
        self.credentials = self.create_credentials()
        self.service = self.create_service()

    def create_credentials(self):
        return service_account.Credentials.from_service_account_file(self.cred_json_path)
    
    def create_service(self):
        return discovery.build('compute', 'v1', credentials=self.credentials)
    
    def get_project_id(self):
        """获取当前凭证的project_id
        """
        return self.credentials.project_id

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

    def _wait_for_global_operation(self, operation_name):
        """等待全局操作结束
        """
        project_id = self.credentials.project_id
        while True:
            result = self.service.globalOperations().get(
                project=project_id,
                operation=operation_name
            ).execute()

            if result['status'] == 'DONE':
                if 'error' in result:
                    raise RuntimeError(result['error'])
                return result

            time.sleep(2)


    def _wait_for_region_operation(self, region, operation_name):
        """等待区域操作结束
        """
        project_id = self.credentials.project_id
        while True:
            result = self.service.regionOperations().get(
                project=project_id,
                region=region,
                operation=operation_name
            ).execute()

            if result['status'] == 'DONE':
                if 'error' in result:
                    raise RuntimeError(result['error'])
                return result

            time.sleep(2)


    def _wait_for_zone_operation(self, zone, operation_name):
        """等待可用区操作结束
        """
        project_id = self.credentials.project_id
        while True:
            result = self.service.zoneOperations().get(
                project=project_id,
                zone=zone,
                operation=operation_name
            ).execute()

            if result['status'] == 'DONE':
                if 'error' in result:
                    raise RuntimeError(result['error'])
                return result

            time.sleep(2)


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

    def list_zone_instances(self, zone):
        """查询可用区下的虚拟机列表

        Args:
            zone (string): 可用区

        Returns:
            list: 可用区下的实例列表
        """
        project_id = self.credentials.project_id
        request = self.service.instances().list(project=project_id, zone=zone, maxResults=500)
        instances = []

        while request is not None:
            response = request.execute()
            if 'items' in response:
                instances.extend(response['items'])
            request = self.service.instances().list_next(previous_request=request, previous_response=response)

        return instances
    
    def list_region_instances(self, region):
        """查询区域的虚拟机列表

        Args:
            region (string): 区域

        Returns:
            list: 区域下的实例列表
        """
        region_zones = self.list_zones_of_region(region)
        instances = []

        for zone in region_zones:
            zone_instances = self.list_zone_instances(zone['name'])
            instances.extend(zone_instances)

        return instances

    def create_vm(self, zone, instance_config):
        """创建虚拟机

        Args:
            zone (string): 可用区
            instance_config (dict): 实例配置字典
        """
        project_id = self.credentials.project_id
        return self.service.instances().insert(project=project_id, zone=zone, body=instance_config).execute()

    def stop_vm(self, zone, instance_name):
        """停止虚拟机实例
        """
        project_id = self.credentials.project_id
        return self.service.instances().stop(
                    project=project_id,
                    zone=zone,
                    instance=instance_name
                ).execute()

    def delete_vm(self, zone, instance_name):
        """销毁虚拟机实例(注意：只是销毁实例，没有清理关联的数据盘和弹性ip, 
        如果要删除相关资源，请使用下面的delete_vm_with_related_resource)
        """
        project_id = self.credentials.project_id
        return self.service.instances().delete(
                    project=project_id,
                    zone=zone,
                    instance=instance_name
                ).execute()

    def delete_vm_with_related_resource(self, region, zone, instance_name):
        elastic_ips = self.list_elastic_ips(region, including_global=True)

        m = {item["address"]: item["name"] for item in elastic_ips}
        vm_info = self.get_vm_info(zone, instance_name)

        delete_operation = self.delete_vm(zone, vm_info["name"])
        self._wait_for_zone_operation(zone, delete_operation["name"])

        # 删除关联的数据盘
        for disk in vm_info['disks']:
            if not disk['boot']:
                try:
                    # 数据盘可以设置为随实例删除而删除，如果数据盘被提前删掉了，下面直接忽略not found错误
                    self.delete_disk(zone, disk["deviceName"])
                    print(f"成功回收磁盘 {disk['deviceName']}")
                except HttpError as e:
                    if e.resp.status != 404:
                        raise

        # 如果关联了弹性ip则释放弹性ip
        for network_interface in vm_info.get("networkInterfaces", []):
            for access_config in network_interface.get("accessConfigs", []):
                if "natIP" in access_config and access_config["natIP"] in m:
                    nat_ip = access_config["natIP"]
                    ok = self.release_elastic_ip(region, m[nat_ip])
                    if not ok:
                        raise RuntimeError(f"回收弹性ip {nat_ip} 失败.")


    def list_instance_groups(self, region):
        """查询instance group列表
        """
        data = []
        project_id = self.credentials.project_id
        region_zones = self.list_zones_of_region(region)
        for zone in region_zones:
            instance_group_request = self.service.instanceGroups().list(project=project_id, zone=zone['name'])
            while instance_group_request is not None:
                instance_group_response = instance_group_request.execute()
                if 'items' in instance_group_response:
                    data.extend(instance_group_response['items'])
                instance_group_request = self.service.instanceGroups().list_next(previous_request=instance_group_request, previous_response=instance_group_response)
        return data


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
        """查询所有可用区详情列表
        """
        data = self._list_all_zones()
        return sorted(data, key=lambda x: x['name'], reverse=False)

    def list_zones_of_region(self, region):
        """查询所有可用区详情列表
        """
        data = self._list_all_zones()
        result = [
            item for item in data if item["name"].startswith(region)
        ]
        return sorted(result, key=lambda x: x['name'], reverse=False)

    def _list_all_zones(self):
        result = []
        request = self.service.zones().list(
            project=self.credentials.project_id, maxResults=500
        )
        while request is not None:
            response = request.execute()
            result.extend(response['items'])
            request = self.service.zones().list_next(
                previous_request=request, previous_response=response
            )
        return result

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
        """查询磁盘类型列表
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

    def list_elastic_ips(self, region, filter_status=None, including_global=False):
        """查询弹性ip列表

        谷歌云的弹性ip和区域关联, 不能在一个虚拟机上关联其他区域的ip

        Args:
            region (string): 区域
            filter_status (string, optional): ip地址状态，使用该字段过滤ip地址列表。默认返回全部数据。
                可选值: 
                    IN_USE: 表示 IP 地址已经关联了一个资源,比如一个vm
                    RESERVED: 表示 IP 地址目前没有关联任何资源
                    None: 不过滤
            including_global: 结果中包含全球范围的弹性ip
        """
        data = []
        project_id = self.credentials.project_id
        request = self.service.addresses().list(project=project_id, region=region)

        while request is not None:
            response = request.execute()
            if 'items' in response:
                data.extend(response['items'])
            request = self.service.addresses().list_next(previous_request=request, previous_response=response)
        
        if including_global:
            global_request = self.service.globalAddresses().list(project=project_id)
            while global_request is not None:
                global_response = global_request.execute()
                if 'items' in global_response:
                    data.extend(global_response['items'])
                global_request = self.service.globalAddresses().list_next(previous_request=global_request, previous_response=global_response)

        if filter_status is None:
            return data

        return [item for item in data if item["status"] == filter_status]

    def list_global_elastic_ips(self):
        """查询全球性弹性ip列表
        """
        data = []
        project_id = self.credentials.project_id
        global_request = self.service.globalAddresses().list(project=project_id)
        while global_request is not None:
            global_response = global_request.execute()
            if 'items' in global_response:
                data.extend(global_response['items'])
            global_request = self.service.globalAddresses().list_next(previous_request=global_request, previous_response=global_response)
        return data
    

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

    def release_elastic_ip(self, region, address_name):
        """释放弹性ip

        同时尝试回收全球性弹性ip和区域性弹性ip

        Args:
            region (string): 区域
            address_name (string): 弹性ip地址名称
        """
        global_error = None
        regional_error = None
        project_id = self.credentials.project_id

        try:
            self.service.globalAddresses().delete(
                project=project_id,
                address=address_name
            ).execute()
        except HttpError as e:
            if e.resp.status == 404:
                global_error = e
            else:
                print(f"删除全球性 IP '{address_name}' 时发生错误: {e}")

        try:
            self.service.addresses().delete(
                project=project_id,
                region=region,
                address=address_name
            ).execute()
        except HttpError as e:
            if e.resp.status == 404:
                regional_error = e
            else:
                print(f"删除区域性 IP '{address_name}' 时发生错误: {e}")

        if global_error and regional_error:
            print(f"IP '{address_name}' 不存在（全球性和区域性弹性 IP 都不存在）。")
            return None

        print(f"成功删除 IP '{address_name}'。")
        return True

    def delete_disk(self, zone, disk_name):
        """删除数据盘
        Args:
            region (string): 区域
            disk_name (string): 磁盘名称
        """
        project_id = self.credentials.project_id
        return self.service.disks().delete(
                    project=project_id,
                    zone=zone,
                    disk=disk_name
                ).execute()

    def list_health_checks(self):
        """查询Health checks列表
        """
        data = []
        project_id = self.credentials.project_id
        health_check_request = self.service.healthChecks().list(project=project_id)
        while health_check_request is not None:
            health_check_response = health_check_request.execute()
            if 'items' in health_check_response:
                data.extend(health_check_response['items'])
            health_check_request = self.service.healthChecks().list_next(previous_request=health_check_request, previous_response=health_check_response)
        return data
    

    def list_ssl_certificates(self):
        """查询 SSL 证书列表"""
        data = []
        project_id = self.credentials.project_id
        ssl_certificate_request = self.service.sslCertificates().list(project=project_id)
        while ssl_certificate_request is not None:
            ssl_certificate_response = ssl_certificate_request.execute()
            if 'items' in ssl_certificate_response:
                data.extend(ssl_certificate_response['items'])
            ssl_certificate_request = self.service.sslCertificates().list_next(previous_request=ssl_certificate_request, previous_response=ssl_certificate_response)
        return data


    def set_named_ports(self, zone, instance_group_name, named_ports):
        """设置命名端口

        Args:
            zone(string): 可用区
            instance_group_name(string): 实例组名称
            named_ports (dict): 命名端口参数列表。格式如下:
                {
                    "namedPorts": [
                        {
                            "name": "http",
                            "port": 1000
                        },
                        {
                            "name": "http2",
                            "port": 2000
                        }
                    ]
                }
        """
        project_id = self.credentials.project_id
        response = self.service.instanceGroups().setNamedPorts(
                project=project_id, 
                zone=zone, 
                instanceGroup=instance_group_name, 
                body=named_ports
            ).execute()
        self._wait_for_zone_operation(zone, response["name"])
        return response

    def create_backend_service(self, request_body):
        """创建后端服务(backendServices)
        """
        project_id = self.credentials.project_id
        response = self.service.backendServices().insert(project=project_id, body=request_body).execute()
        self._wait_for_global_operation(response["name"])
        return response

    def set_url_maps(self, request_body):
        """创建用于负载均衡的url映射
        """
        project_id = self.credentials.project_id
        response = self.service.urlMaps().insert(project=project_id, body=request_body).execute()
        self._wait_for_global_operation(response["name"])
        return response

    def create_target_http_proxy(self, request_body):
        """创建用于负载均衡的http类型目标代理
        """
        project_id = self.credentials.project_id
        response = self.service.targetHttpProxies().insert(project=project_id, body=request_body).execute()
        self._wait_for_global_operation(response["name"])
        return response

    def create_target_https_proxy(self, request_body):
        """创建用于负载均衡的https类型目标代理
        """
        project_id = self.credentials.project_id
        response = self.service.targetHttpsProxies().insert(project=project_id, body=request_body).execute()
        self._wait_for_global_operation(response["name"])
        return response

    def create_global_forwarding_rule(self, request_body):
        """创建转发规则
        """
        project_id = self.credentials.project_id
        response = self.service.globalForwardingRules().insert(project=project_id, body=request_body).execute()
        self._wait_for_global_operation(response["name"])
        return response

    def list_url_maps(self):
        """查询全局性url映射列表
        """
        data = []
        project_id = self.credentials.project_id
        request = self.service.urlMaps().list(project=project_id)
        while request is not None:
            response = request.execute()
            if 'items' in response:
                data.extend(response['items'])
            request = self.service.urlMaps().list_next(previous_request=request, previous_response=response)
        return data

    def list_region_url_maps(self, region):
        """查询区域性url映射列表
        """
        data = []
        project_id = self.credentials.project_id
        request = self.service.regionUrlMaps().list(project=project_id, region=region)
        while request is not None:
            response = request.execute()
            if 'items' in response:
                data.extend(response['items'])
            request = self.service.regionUrlMaps().list_next(previous_request=request, previous_response=response)
        return data
