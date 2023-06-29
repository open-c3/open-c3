#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import boto3


class LibRds:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()
        self.page_size = 100

    def create_client(self):
        endpoint_url = f"https://rds.{self.region}.amazonaws.com"
        if self.region.startswith("cn"):
            endpoint_url = f"https://rds.{self.region}.amazonaws.com.cn"

        client = boto3.client(
            "rds",
            endpoint_url=endpoint_url,
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )
        return client

    def list_db_snapshot(self):
        def get_instances_from_response(response_data):
            data = response_data["DBSnapshots"]
            for instance in data:
                instance["RegionId"] = self.region
            return data

        def get_data(marker=""):
            response = self.client.describe_db_snapshots(
                MaxRecords=self.page_size, Marker=marker, IncludeShared=True, IncludePublic=True)
            data = get_instances_from_response(response)

            res = {
                "marker": "",
                "data_list": data,
            }
            if "Marker" in response:
                res["marker"] = response["Marker"]
            return res

        result = []
        res = get_data("")
        result.extend(res["data_list"])
        marker = res["marker"]

        while marker != "":
            res = get_data(marker)
            result.extend(res["data_list"])
            marker = res["marker"]
        return result
