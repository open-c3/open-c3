#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import threading
import time
import sys
from huaweicloudsdkiam.v3 import *
from huaweicloudsdkdns.v2 import *
from huaweicloudsdkcore.region.region import Region
from huaweicloudsdkcore.exceptions import exceptions
from huaweicloudsdkdns.v2.region.dns_region import DnsRegion
from huaweicloudsdkcore.auth.credentials import GlobalCredentials, BasicCredentials

MAX_THREADS = 30
MAX_RETRIES = 3
RETRY_DELAY = 1

class ThreadSafeArray:
    def __init__(self):
        self._array = []
        self._lock = threading.Lock()

    def append(self, value):
        with self._lock:
            self._array.append(value)

    def extend(self, values):
        with self._lock:
            self._array.extend(values)

class HuaweiCloudDNS(object):
    def __init__(self, access_key, secret_key, project_id, region):
        self.access_key = access_key
        self.secret_key = secret_key
        self.region = region
        self.project_id = project_id if project_id not in [None, "None"] else self.get_project_id()
        self.client = self.create_client()

    def get_project_id(self):
        # 定义 IAM 端点映射
        iam_endpoints = {
            "eu-west-101": "https://iam.myhuaweicloud.eu",  # 都柏林地区
            "default": "https://iam.myhuaweicloud.com"  # 默认端点
        }

        # 选择合适的 IAM 端点
        iam_endpoint = iam_endpoints.get(self.region, iam_endpoints["default"])

        credentials = GlobalCredentials(self.access_key, self.secret_key)
        iam_client = IamClient.new_builder() \
            .with_credentials(credentials) \
            .with_endpoint(iam_endpoint) \
            .build()

        try:
            request = KeystoneListProjectsRequest()
            response = iam_client.keystone_list_projects(request)
            for project in response.projects:
                if project.name == self.region:
                    return project.id

            raise Exception(f"No project found for region {self.region}")
        except exceptions.ClientRequestException as e:
            print(f"Failed to get project ID: {e}")
            sys.exit(1)


    def create_client(self):
        credentials = BasicCredentials(self.access_key, self.secret_key, self.project_id)
        return DnsClient.new_builder() \
            .with_credentials(credentials) \
            .with_region(DnsRegion.value_of(self.region)) \
            .build()

    def get_public_zones(self):
        request = ListPublicZonesRequest()
        response = self.client.list_public_zones(request)
        return response.zones

    def get_private_zones(self):
        request = ListPrivateZonesRequest()
        request.type = "private"
        response = self.client.list_private_zones(request)
        return response.zones

    def get_all_recordsets(self, zone_id, zone_type):
        all_records = []
        marker = None
        limit = 500

        while True:
            request = ListRecordSetsRequest()
            request.zone_id  = zone_id
            request.limit = limit

            if zone_type == 'private':
                request.zone_type = "private"

            if marker:
                request.marker = marker

            response = self.client.list_record_sets(request)
            all_records.extend(response.recordsets)

            if len(response.recordsets) < limit:
                break

            marker = response.recordsets[-1].id

        return all_records

    def get_zone_tags(self, zone_id, zone_type):
        request = ShowResourceTagRequest()
        request.resource_id = zone_id
        request.resource_type = "DNS-public_zone" if zone_type == 'public' else "DNS-private_zone"
        response = self.client.show_resource_tag(request)
        return response.tags
    def get_subdomains(self):
        public_zones = self.get_public_zones()
        private_zones = self.get_private_zones()
        all_zones = public_zones + private_zones
        result = ThreadSafeArray()

        def worker(zone):
            for attempt in range(MAX_RETRIES):
                try:
                    records = self.get_all_recordsets(zone.id, zone.zone_type)
                    zone_tags = self.get_zone_tags(zone.id, zone.zone_type)
                    zone_name = zone.name.rstrip('.')

                    subdomains = []
                    for record in records:
                        fqdn = record.name.rstrip('.')

                        if fqdn.endswith('.' + zone_name):
                            host_name = fqdn[:-len(zone_name)-1] if fqdn != zone_name else '@'
                            sld_name = zone_name
                        else:
                            continue

                        records = [value.rstrip('.') for value in record.records]
                        records_values = ','.join(records)  

                        subdomains.append({
                            "uuid": record.id,
                            "host_name": host_name,
                            "host_domain_name": fqdn,
                            "sld_name": sld_name,
                            "xns_sld_id": zone.id,
                            "record_type": record.type,
                            "records": record.records,
                            "record_values": records_values,
                            "record_info": json.dumps([record.to_dict()], default=str),
                            "Tag": zone_tags,
                            "zone_type": zone.zone_type,
                            "region": self.region
                        })

                    result.extend(subdomains)
                    break
                except exceptions.ClientRequestException as e:
                    if attempt == MAX_RETRIES - 1:
                        print(f"Failed to process zone {zone.name} after {MAX_RETRIES} attempts: {e}")
                    else:
                        time.sleep(RETRY_DELAY)

        threads = []
        for zone in all_zones:
            while threading.active_count() > MAX_THREADS:
                time.sleep(0.1)
            t = threading.Thread(target=worker, args=(zone,))
            threads.append(t)
            t.start()

        for t in threads:
            t.join()

        return result._array
