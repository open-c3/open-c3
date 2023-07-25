#!/usr/bin/env /data/Software/mydan/python3/bin/python3
# -*- coding: utf-8 -*-

import boto3
import time


class ELBV2:
    def __init__(self, access_id, access_key, region):
        self.access_id = access_id
        self.access_key = access_key
        self.region = region
        self.client = self.create_client()
        # 查询标签时，为了提高速度，使用了批量查询
        # 但是批量查询一次最多只能查20个，所以这里使用了
        # 较小的每页数目
        self.page_size = 20

    def create_client(self):
        client = boto3.client(
            "elbv2",
            aws_access_key_id=self.access_id,
            aws_secret_access_key=self.access_key,
            region_name=self.region,
        )
        return client

    def get_instances_from_response(self, response_data):
        return response_data["LoadBalancers"]
    
    def show_lb_info(self, load_balancer_arn):
        """查询elbv2详情。如果不存在则返回None

        Args:
            load_balancer_name (str): elb名称
        """
        try:
            resp = self.client.describe_load_balancers(LoadBalancerArns=[load_balancer_arn])
            if 'LoadBalancers' not in resp or not len(resp['LoadBalancers']):
                return None
        except Exception as e:
            if "One or more load balancers not found" in str(e):
                return None
            raise e
        
        return resp['LoadBalancers'][0]

    def list_instances(self):
        def get_data(next_marker):
            res = {
                "next_marker": "",
                "data_list": [],
                "arn_tag_dict": {}
            }
            response = self.client.describe_load_balancers(
                PageSize=self.page_size, Marker=next_marker)
            arn_list = []
            data_list = self.get_instances_from_response(response)
            if len(data_list) == 0:
                return res

            for instance in data_list:
                arn_list.append(instance["LoadBalancerArn"])

            d = self.list_tags(arn_list)

            res["data_list"] = data_list
            res["arn_tag_dict"] = d

            if "NextMarker" in response:
                res["next_marker"] = response["NextMarker"]
            return res

        arn_tag_dict = {}
        next_marker = ""
        result = []

        res = get_data("")
        if res["arn_tag_dict"] is not None:
            arn_tag_dict = dict(list(arn_tag_dict.items()) +
                                list(res["arn_tag_dict"].items()))
        result.extend(res["data_list"])
        next_marker = res["next_marker"]

        while next_marker != "":
            res = get_data(next_marker)
            if res["arn_tag_dict"] is not None:
                arn_tag_dict = dict(list(arn_tag_dict.items()) +
                                    list(res["arn_tag_dict"].items()))
            result.extend(res["data_list"])
            next_marker = res["next_marker"]

        for i, s in enumerate(result):
            if s["LoadBalancerArn"] in arn_tag_dict:
                result[i]["Tag"] = arn_tag_dict[s["LoadBalancerArn"]]
        return result

    def list_tags(self, arn_list):
        """查询标签

        Args:
            arn_list (list): arn列表
        """
        tag_resp = self.client.describe_tags(ResourceArns=arn_list)
        return {
            instance_tag["ResourceArn"]: instance_tag["Tags"]
            for instance_tag in tag_resp["TagDescriptions"]
        }

    def get_instance_list(self, resource_type):
        """查询elbv2实例列表

        Args:
            resource_type (str): 类型，可选值为: application、network
        """
        instance_list = self.list_instances()

        return [
            instance
            for instance in instance_list
            if instance["Type"] == resource_type
        ]
    
    def describe_target_groups(self, load_balancer_arn):
        """
        查询elb的target groups列表
        """
        if not load_balancer_arn:
            raise RuntimeError("不允许 load_balancer_arn 参数为空")

        target_groups = []
        next_token = None

        while True:
            if next_token:
                response = self.client.describe_target_groups(LoadBalancerArn=load_balancer_arn, Marker=next_token)
            else:
                response = self.client.describe_target_groups(LoadBalancerArn=load_balancer_arn)

            target_groups.extend(response['TargetGroups'])

            # 检查是否有更多分页
            if 'NextMarker' in response:
                next_token = response['NextMarker']
            else:
                break

        return target_groups
    
    def delete_target_group(self, target_group_arn):
        """删除指定的target group

        Args:
            target_group_arn (str): target group的arn
        """
        return self.client.delete_target_group(
            TargetGroupArn=target_group_arn
        )

    
    def delete_load_balancer(self, load_balancer_arn):
        """删除elbv2

        Args:
            load_balancer_arn (str): elbv2的arn
        """
        target_group_list = self.describe_target_groups(load_balancer_arn)
        for target_group in target_group_list:
            # 打印出target group的arn，防止后续出错找不到关联的target group arn
            print(f"关联的target group arn: {target_group['TargetGroupArn']}")

        self.client.delete_load_balancer(
            LoadBalancerArn=load_balancer_arn
        )

        # 等待云端删掉 alb
        now = time.time()
        timeout = 900
        while True:
            if time.time() - now > timeout:
                raise RuntimeError(f"等待 {timeout} 秒后云端依然没有删掉 alb {load_balancer_arn}") 
            
            if not self.show_lb_info(load_balancer_arn):
                break

            time.sleep(5)
        
        # C3TODO 20230725 测试发现删除lb后马上删除target group会有异常
        # 没找到其他合适的办法，这里先临时休眠一阵子。假如休眠
        # 时间不足，则执行下面的操作会出错
        time.sleep(100)

        for target_group in target_group_list:
            self.delete_target_group(target_group["TargetGroupArn"])

