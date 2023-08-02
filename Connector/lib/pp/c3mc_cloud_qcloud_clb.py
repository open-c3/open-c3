#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import json
import time
import sys

from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
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
    
    def describe_load_balancers(self, load_balancer_id_list=None):
        """查询负载均衡器列表列表
        如果指定了负载均衡器id列表, 则专门查询列表中负载均衡器的详情。否则查询所有实例
        """
        result = []
        req = models.DescribeLoadBalancersRequest()
        for i in range(sys.maxsize):
            params = {
                "Offset": i * 100,
                "Limit": 100
            }
            if load_balancer_id_list:
                params["LoadBalancerIds"] = load_balancer_id_list

            req.from_json_string(json.dumps(params))

            resp = self.client.DescribeLoadBalancers(req)

            instance_list = json.loads(resp.to_json_string())["LoadBalancerSet"]

            if len(instance_list) == 0:
                break
            result.extend(instance_list)
        return result
    
    def get_vip_of_load_balancer(self, load_balancer_id, timeout=600):
        """
        获取指定负载均衡器的vip列表
        """
        start_time = time.time()
        while True:
            clb_info = self.describe_load_balancers([load_balancer_id])[0]
            if clb_info["LoadBalancerVips"]:
                return clb_info["LoadBalancerVips"]
            elif time.time() - start_time > timeout:
                raise RuntimeError(f"等待 {timeout} 秒后依然无法获取 vip 列表")
            else:
                time.sleep(5)

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
        return json.loads(resp.to_json_string())

    def delete_listeners(self, load_balancer_id, listener_id_list):
        """删除监听器

        Args:
            load_balancer_id (str): 负载均衡器实例id
            listener_id_list (list): 监听器id列表
        """
        req = models.DeleteLoadBalancerListenersRequest()
        params = {
            "LoadBalancerId": load_balancer_id,
            "ListenerIds": listener_id_list
        }
        req.from_json_string(json.dumps(params))

        resp = self.client.DeleteLoadBalancerListeners(req)
        return json.loads(resp.to_json_string())

    def delete_rules(self, load_balancer_id, listener_id, location_id_list):
        """删除负载均衡七层监听器的转发规则

        Args:
            load_balancer_id (str): 负载均衡器实例id
            listener_id (str): 监听器id
            location_id_list (list): 七层监听器转发规则的id列表
        """
        req = models.DeleteRuleRequest()
        params = {
            "LoadBalancerId": load_balancer_id,
            "ListenerId": listener_id,
            "LocationIds": location_id_list
        }
        req.from_json_string(json.dumps(params))

        timeout = 900

        begin = time.time()
        while True:
            try:
                resp = self.client.DeleteRule(req)
                return json.loads(resp.to_json_string())
            except Exception as e:
                if time.time() - begin > timeout:
                    raise RuntimeError(f"等待 {timeout} 秒后仍旧无法创建转发规则") from e

                if "Your task is working" in str(e):
                    time.sleep(5)
                    continue
    
    def wait_until_task_finish(self, request_id, timeout=600):
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
