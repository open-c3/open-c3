#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import time

from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.tag.v20180813 import tag_client, models


class QcloudTag:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        """创建tag sdk客户端
        """
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "tag.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return tag_client.TagClient(cred, self.region, clientProfile)
    
    def tag_query(self, rid):
        """使用腾讯云资源六段式表示法获取标签列表

        Args:
            rid (str): 资源六段式表示法
        """
        def get_page_tags(pagination_token=None):
            # 实例化一个请求对象,每个接口都会对应一个request对象
            req = models.GetResourcesRequest()
            params = {
                "ResourceList": [ rid ],
                "MaxResults": 200
            }
            if pagination_token is not None:
                params["PaginationToken"] = pagination_token

            req.from_json_string(json.dumps(params))
            resp = self.client.GetResources(req)
            return json.loads(resp.to_json_string())
         
        data = []

        resp = get_page_tags()

        token = resp["PaginationToken"]
        tag_list = resp["ResourceTagMappingList"][0]["Tags"]
        data.extend(tag_list)

        if token == "" or len(tag_list) == 0:
           return data
       
        while token != "":
            resp = get_page_tags()
            token = resp["PaginationToken"]
            tag_list = resp["ResourceTagMappingList"][0]["Tags"]
            data.extend(tag_list)

            if token == "" or len(tag_list) == 0:
                break
        
        return data


    def tag_add(self, rid, tag_list):
        """增加标签

        Args:
            rid (str): rid
            tag_list (list): 标签列表，格式为 [{"key": "key1", "value": "value1"}]
        """
        req = models.TagResourcesRequest()
        params = {
            "ResourceList": [rid],
            "Tags": [{"TagKey": item["key"], "TagValue": item["value"]} for item in tag_list]
        }
        req.from_json_string(json.dumps(params))

        self.client.TagResources(req)
    
    def tag_delete(self, rid, key_list):
        """删除指定的标签

        Args:
            rid (str): rid
            tag_key (list): 要删除的标签键列表
        """
        req = models.UnTagResourcesRequest()
        params = {
            "ResourceList": [rid],
            "TagKeys": key_list
        }
        req.from_json_string(json.dumps(params))

        self.client.UnTagResources(req)
    
    def add_tag_by_replace(self, rid, tag_list):
        """添加标签。但是会删除在忽略大小写的情况下旧的标签
        比如, 现在实例已经有了标签键 test, 要添加的标签里有 TEST 标签键。则会删除 test 标签并添加 TEST 标签
        """
        def split_tag_list(curr_tag_list):
            need_delete_keys = []

            for tag in tag_list:
                need_delete_keys.extend(
                    curr_tag["TagKey"]
                    for curr_tag in curr_tag_list
                    if tag["key"].lower() == curr_tag["TagKey"].lower()
                    and tag["key"] != curr_tag["TagKey"]
                )
            return need_delete_keys
        
        def check_if_ok():
            curr_tag_list = self.tag_query(rid)

            m = {tag["TagKey"] for tag in curr_tag_list}

            for tag in curr_tag_list:
                if tag["TagKey"] not in m:
                    return False
            return True

        curr_tag_list = self.tag_query(rid)
        need_delete_keys = split_tag_list(curr_tag_list)

        def run():
            # 添加新的标签
            self.tag_add(rid, tag_list)
            if need_delete_keys:
                # 删除大小写同名的旧标签
                self.tag_delete(rid, need_delete_keys)
        run()

        # 检查新标签是否添加成功
        ok = False
        while not ok:
            ok = check_if_ok()
            time.sleep(5)
            run()




