#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import boto3


class Vpc:
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

    def show_vpc(self, vpc_id):
        response = self.client.describe_vpcs(
            VpcIds=[
                vpc_id,
            ],
        )
        return response["Vpcs"][0]
