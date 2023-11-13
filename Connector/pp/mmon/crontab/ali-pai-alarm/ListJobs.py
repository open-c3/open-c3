#!/data/Software/mydan/python3/bin/python3


#!/usr/bin/env python
#coding=utf-8

import os
from aliyunsdkcore.client import AcsClient
from aliyunsdkcore.request import CommonRequest
from aliyunsdkcore.auth.credentials import AccessKeyCredential
from aliyunsdkcore.auth.credentials import StsTokenCredential
from datetime import datetime, timedelta

# Please ensure that the environment variables ALIBABA_CLOUD_ACCESS_KEY_ID and ALIBABA_CLOUD_ACCESS_KEY_SECRET are set.
credentials = AccessKeyCredential(os.environ['ALIBABA_CLOUD_ACCESS_KEY_ID'], os.environ['ALIBABA_CLOUD_ACCESS_KEY_SECRET'])
# use STS Token
# credentials = StsTokenCredential(os.environ['ALIBABA_CLOUD_ACCESS_KEY_ID'], os.environ['ALIBABA_CLOUD_ACCESS_KEY_SECRET'], os.environ['ALIBABA_CLOUD_SECURITY_TOKEN'])
client = AcsClient(region_id='cn-wulanchabu', credential=credentials)

request = CommonRequest()
request.set_accept_format('json')
request.set_method('GET')
request.set_protocol_type('https') # https | http
request.set_domain('pai-dlc.cn-wulanchabu.aliyuncs.com')
request.set_version('2020-12-03')

request.add_query_param('ShowOwn', "false")
request.add_query_param('Status', "Running")


def getTime():
    current_time = datetime.now()
    current_time -= timedelta(hours=8)
    tmp = current_time - timedelta(days=30)
    time_format = "%Y-%m-%dT%H:%M:00.00Z"
    time_string_40_minutes_ago = tmp.strftime(time_format)
    return time_string_40_minutes_ago


startime = getTime()

request.add_query_param('StartTime', startime)

request.add_header('Content-Type', 'application/json')
request.set_uri_pattern('/api/v1/jobs')


response = client.do_action_with_exception(request)

# python2:  print(response) 
print(str(response, encoding = 'utf-8'))
