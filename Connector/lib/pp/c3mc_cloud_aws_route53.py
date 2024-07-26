#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import threading
import time
import sys
import boto3

sys.path.append("/data/Software/mydan/Connector/lib/pp")
from c3mc_utils import calculate_md5

MAX_THREADS = 30

class ThreadSafeArray:
    def __init__(self):
        self._array = []
        self._lock = threading.Lock()

    def append(self, value):
        with self._lock:
            self._array.append(value)

class AwsRoute53:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.route53_client = self.create_client('route53')
        self.ec2_clients = {}
        self.vpc_cache = {}

    def create_client(self, service, region=None):
        return boto3.client(
            service,
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=region or self.region,
        )

    def get_ec2_client(self, region):
        if region not in self.ec2_clients:
            self.ec2_clients[region] = self.create_client('ec2', region)
        return self.ec2_clients[region]

    def get_domain_tags(self, hosted_zone_ids):
        all_tags = {}
        grouped_ids = [hosted_zone_ids[i:i+10] for i in range(0, len(hosted_zone_ids), 10)]

        for group in grouped_ids:
            response = self.route53_client.list_tags_for_resources(ResourceType='hostedzone', ResourceIds=group)
            tag_sets = response['ResourceTagSets']

            for tag_set in tag_sets:
                resource_id = tag_set['ResourceId']
                tags = tag_set['Tags']
                all_tags[resource_id] = tags

        return all_tags

    def get_domains(self):
        hosted_zones = []
        response = self.route53_client.list_hosted_zones()
        hosted_zones.extend(response['HostedZones'])

        while response['IsTruncated']:
            response = self.route53_client.list_hosted_zones(Marker=response['NextMarker'])
            hosted_zones.extend(response['HostedZones'])

        return hosted_zones

    def get_domain_records(self, hosted_zone_id):
        records = []
        next_record_name = None
        next_record_type = None

        id_str = hosted_zone_id.lstrip("/hostedzone/")

        while True:
            if next_record_name is not None:
                response = self.route53_client.list_resource_record_sets(
                    HostedZoneId=id_str,
                    StartRecordName=next_record_name,
                    StartRecordType=next_record_type
                )
            else:
                response = self.route53_client.list_resource_record_sets(
                    HostedZoneId=id_str,
                )
            
            records.extend(response['ResourceRecordSets'])

            if response['IsTruncated']:
                next_record_name = response['NextRecordName']
                next_record_type = response['NextRecordType']
            else:
                break
        
        return records

    def get_vpc_region(self, vpc_id):
        if vpc_id in self.vpc_cache:
            return self.vpc_cache[vpc_id]

        regions = boto3.session.Session().get_available_regions('ec2')
        for region in regions:
            try:
                ec2_client = self.get_ec2_client(region)
                response = ec2_client.describe_vpcs(VpcIds=[vpc_id])
                if 'Vpcs' in response and response['Vpcs']:
                    self.vpc_cache[vpc_id] = region
                    return region
            except Exception as e:
                pass
            time.sleep(0.1)  # 添加短暂延迟以避免 API 限制

        return None

    def get_subdomains(self):
        domains = self.get_domains()

        def worker(array, domain):
            try:
                records = self.get_domain_records(domain["Id"])
                m = {}
                for record in records:
                    if record["Name"] not in m:
                        m[record["Name"]] = []
                    m[record["Name"]].append(record)

                # 获取域名的region
                domain_region = self.region  # 默认使用传入的region
                if domain['Config']['PrivateZone']:
                    # 私有域名，获取关联VPC的region
                    zone_details = self.route53_client.get_hosted_zone(Id=domain['Id'])
                    if 'VPCs' in zone_details and zone_details['VPCs']:
                        vpc_id = zone_details['VPCs'][0]['VPCId']
                        vpc_region = self.get_vpc_region(vpc_id)
                        if vpc_region:
                            domain_region = vpc_region

                for record_name in m:
                    host_domain_name = record_name.rstrip(".")

                    # 提取记录值
                    record_values = []
                    for record in m[record_name]:
                        if 'ResourceRecords' in record:
                            record_values.extend([rr['Value'] for rr in record['ResourceRecords']])
                        elif 'AliasTarget' in record:
                            record_values.append(record['AliasTarget']['DNSName'])

                    array.append({
                        "uuid": calculate_md5(self.access_id + host_domain_name),
                        "host_name": record_name.split(f".{domain['Name']}")[0],
                        "host_domain_name": host_domain_name,
                        "sld_name": domain["Name"].rstrip("."),
                        "xns_sld_id": domain["Id"].lstrip("/hostedzone/"),
                        "record_values": ",".join(record_values),
                        "record_info": json.dumps(m[record_name], default=str),
                        "region": domain_region,
                        "type": "private" if domain['Config']['PrivateZone'] else "public"
                    })
            except Exception as e:
                print(f"Error processing domain {domain['Name']}: {str(e)}")
        
        array = ThreadSafeArray()
        threads = []

        for domain in domains:
            while threading.active_count() > MAX_THREADS: 
                time.sleep(0.1)
            t = threading.Thread(target=worker, args=(array, domain))
            threads.append(t)
            t.start()

        for t in threads:
            t.join()
        
        # 获取标签
        domain_ids = [domain["Id"].lstrip("/hostedzone/") for domain in domains]
        domain_tags_dict = self.get_domain_tags(domain_ids)

        result = array._array 
        for i in range(len(result)):
            result[i]["Tag"] = domain_tags_dict[result[i]["xns_sld_id"]]

        return result
