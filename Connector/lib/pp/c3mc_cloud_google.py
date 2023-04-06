#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import re

from googleapiclient import discovery
from google.oauth2 import service_account



class Google:
    def __init__(self, cred_json_path):
        self.cred_json_path = cred_json_path
        self.credentials = self.create_credentials()

    def create_credentials(self):
        return service_account.Credentials.from_service_account_file(self.cred_json_path)
    
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

        service = discovery.build('compute', 'v1', credentials=self.credentials)
        request = service.disks().get(project=project, zone=zone, disk=disk)
        return request.execute()

    
    def get_image_info(self, image_source):
        result = re.search(r'projects/(.*?)/', image_source)
        project = result[1]

        image = image_source.split("/")[-1]

        service = discovery.build('compute', 'v1', credentials=self.credentials)
        request = service.images().get(project=project, image=image)
        return request.execute()
