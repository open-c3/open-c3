#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import time

from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.common.exception.tencent_cloud_sdk_exception import TencentCloudSDKException
from tencentcloud.clb.v20180317 import clb_client, models


class QcloudClb:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()

    def create_client(self):
        cred = credential.Credential(self.access_id, self.access_key)
        httpProfile = HttpProfile()
        httpProfile.endpoint = "clb.tencentcloudapi.com"

        clientProfile = ClientProfile()
        clientProfile.httpProfile = httpProfile
        return clb_client.ClbClient(cred, self.region, clientProfile)

    def delete_load_balancer(self, load_balancer_id_list):
        """使用腾讯云接口回收一个或多个负载均衡器实例

        Args:
            load_balancer_id_list (list): 负载均衡器实例id列表
        """
        req = models.DeleteLoadBalancerRequest()
        params = {
            "LoadBalancerIds": load_balancer_id_list
        }
        req.from_json_string(json.dumps(params))

        # 返回的resp是一个DeleteLoadBalancerResponse的实例，与请求对象对应
        resp = self.client.DeleteLoadBalancer(req)

        self._wait_until_task_finish(resp.RequestId)


    def _wait_until_task_finish(self, request_id, timeout=600):
        """
        根据request_id查询并等待异步任务结束
        """
        start_time = time.time()
        while True:
            req = models.DescribeTaskStatusRequest()
            params = {
                "TaskId": request_id
            }
            req.from_json_string(json.dumps(params))
            resp = self.client.DescribeTaskStatus(req)

            status = resp.Status
            if status == 0:
                return True
            elif status == 1:
                print(f"任务操作失败. resp = {json.dumps(resp)}")
                return False
            elif time.time() - start_time > timeout:
                return False
            else:
                time.sleep(5)
