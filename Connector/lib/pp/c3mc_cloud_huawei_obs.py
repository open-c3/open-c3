#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import threading
import time

from obs import ObsClient


# 并发处理所有存储桶的最大线程数
MAX_CONCURRENT_NUMBER = 13


class ThreadSafeArray:
    def __init__(self):
        self._array = []
        self._lock = threading.Lock()

    def append(self, value):
        with self._lock:
            self._array.append(value)


class HuaweiObs:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        return ObsClient(
            access_key_id=self.access_id,
            secret_access_key=self.access_key,
            server=f"https://obs.{self.region}.myhuaweicloud.com/",
        )

    def list_buckets(self):
        resp = self.client.listBuckets(isQueryLocation=True)
        array = ThreadSafeArray()
        threads = []

        def get_tag_for_bucket(array, bucket):
            item = {
                "uuid": f"obs-{bucket['location']}-{bucket['name']}",
                "name": bucket['name'],
                "create_date": bucket['create_date'],
                "location": bucket['location'],
                "tags": [],
            }
            tag_res = self.list_tags_of_bucket(item)
            if tag_res.status == 200:
                for tag_item in tag_res.body.tagSet:
                    item["tags"].append(
                        {
                            "key": tag_item.key,
                            "value": tag_item.value,
                        }
                    )
            array.append(item)

        for bucket in resp.body.buckets:
            if threading.active_count() > MAX_CONCURRENT_NUMBER:
                time.sleep(0.3)
            
            t = threading.Thread(
                target=get_tag_for_bucket,
                args=(array, bucket),
            )
            threads.append(t)
            t.start()
        
        for t in threads:
            t.join()

        return array._array
    
    def list_tags_of_bucket(self, bucket_info):
        return ObsClient(
            access_key_id=self.access_id,
            secret_access_key=self.access_key,
            server=f"https://obs.{bucket_info['location']}.myhuaweicloud.com/",
        ).getBucketTagging(bucket_info['name'])
