#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import sys
import subprocess
import requests
import json
import time
import threading

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


class DnspodSubdomain:
    def __init__(self):
        cmd_parts = ["c3mc-sys-ctl", "cmdb.sync.subdomain.dnspod_token"]
        output = subprocess.run(cmd_parts, capture_output=True, text=True)
        if output.returncode != 0:
            print(output.stderr, file=sys.stderr)
            exit(1)
        dnspod_token = output.stdout.strip()
        self.dnspod_token = dnspod_token
    
    def get_domains(self):
        if self.dnspod_token == "":
            return []
        
        url = "https://dnsapi.cn/Domain.List"

        data = {
            "login_token": self.dnspod_token,
            "format": "json"
        }
        response = requests.post(url, data=data)
        return json.loads(response.text)["domains"]
    
    def get_domain_records(self, domain_id):
        result = []

        url = "https://dnsapi.cn/Record.List"
        # 每次获取的条目数
        limit = 3000
        for i in range(sys.maxsize):

            data = {
                "domain_id": domain_id,

                "offset": i * limit,
                "length": limit,

                "login_token": self.dnspod_token,
                "format": "json",
            }
            response = requests.post(url, data=data)
            response = json.loads(response.text)

            if "records" not in response:
                break

            result.extend(response["records"])
        return result
    
    def get_subdomains(self):
        domains = self.get_domains()

        def worker(array, domain):
            records = self.get_domain_records(domain["id"])
            for record in records:
                record_name = record["name"]
                domain_name = domain["name"].rstrip(".")
                host_domain_name = f"{record_name}.{domain_name}"
                array.append(
                    {
                        "uuid": calculate_md5(host_domain_name),
                        "host_name": record_name,
                        "host_domain_name": host_domain_name,
                        "sld_name": domain_name,
                        "xns_host_id": record["id"],
                        "xns_sld_id": domain["id"],
                        "record_info": json.dumps(record),
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

        return array._array
