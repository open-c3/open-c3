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
        self.client = self.create_client()

    def create_client(self):
        client = boto3.client(
            "route53",
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )
        return client

    def get_domain_tags(self, hosted_zone_ids):
        all_tags = {}

        # list_tags_for_resources接口只允许一次最多查询10个id
        grouped_ids = [hosted_zone_ids[i:i+10] for i in range(0, len(hosted_zone_ids), 10)]

        for group in grouped_ids:
            response = self.client.list_tags_for_resources(ResourceType='hostedzone', ResourceIds=group)
            tag_sets = response['ResourceTagSets']

            for tag_set in tag_sets:
                resource_id = tag_set['ResourceId']
                tags = tag_set['Tags']
                all_tags[resource_id] = tags

        return all_tags

    def get_domains(self):
        hosted_zones = []

        response = self.client.list_hosted_zones()
        hosted_zones.extend(response['HostedZones'])

        while response['IsTruncated']:
            response = self.client.list_hosted_zones(Marker=response['NextMarker'])
            hosted_zones.extend(response['HostedZones'])

        return hosted_zones
    
    def get_domain_records(self, hosted_zone_id):
        records = []
        next_record_name = None
        next_record_type = None

        id_str = hosted_zone_id.lstrip("/hostedzone/")

        while True:
            if next_record_name is not None:
                response = self.client.list_resource_record_sets(
                    HostedZoneId=id_str,
                    StartRecordName=next_record_name,
                    StartRecordType=next_record_type
                )
            else:
                response = self.client.list_resource_record_sets(
                    HostedZoneId=id_str,
                )
            
            records.extend(response['ResourceRecordSets'])

            if response['IsTruncated']:
                next_record_name = response['NextRecordName']
                next_record_type = response['NextRecordType']
            else:
                break
        
        return records

    def get_subdomains(self):
        domains = self.get_domains()

        def worker(array, domain):
            records = self.get_domain_records(domain["Id"])
            m = {}
            for record in records:
                if record["Name"] not in m:
                    m[record["Name"]] = []
                m[record["Name"]].append(record)

            for record_name in m:
                host_domain_name = record_name.rstrip(".")

                array.append(
                    {
                        "uuid": calculate_md5(self.access_id + host_domain_name),
                        "host_name": record_name.split(f".{domain['Name']}")[0],
                        "host_domain_name": host_domain_name,
                        "sld_name": domain["Name"].rstrip("."),
                        "xns_sld_id": domain["Id"].lstrip("/hostedzone/"),
                        "record_info": json.dumps(m[record_name], default=str),
                    }
                )
        
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
        domain_ids = []
        for domain in domains:
            domain_ids.append(domain["Id"].lstrip("/hostedzone/"))
        domain_tags_dict = self.get_domain_tags(domain_ids)

        result = array._array 
        for i in range(len(result)):
            result[i]["Tag"] = domain_tags_dict[result[i]["xns_sld_id"]]

        return result

