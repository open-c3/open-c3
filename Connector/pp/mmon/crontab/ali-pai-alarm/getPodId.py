#!/data/Software/mydan/python3/bin/python3
#coding=utf-8

import os
import sys
from aliyunsdkcore.client import AcsClient
from aliyunsdkcore.request import CommonRequest
from aliyunsdkcore.auth.credentials import AccessKeyCredential
from aliyunsdkcore.auth.credentials import StsTokenCredential

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

jobid = sys.argv[1]
request.add_header('Content-Type', 'application/json')
request.set_uri_pattern(f'/api/v1/jobs/{jobid}')


response = client.do_action_with_exception(request)

# python2:  print(response) 
print(str(response, encoding = 'utf-8'))
