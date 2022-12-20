#!/bin/bash

set -e

/usr/local/python3/bin/pip3.7 install pycrypto -U -i https://pypi.tuna.tsinghua.edu.cn/simple
/usr/local/python3/bin/pip3.7 install pycryptodome -U -i https://pypi.tuna.tsinghua.edu.cn/simple
/usr/local/python3/bin/pip3.7 install -r /app/init/cloud-aliyun-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
/usr/local/python3/bin/pip3.7 install -r /app/init/cloud-aws-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
/usr/local/python3/bin/pip3.7 install -r /app/init/cloud-google-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
/usr/local/python3/bin/pip3.7 install -r /app/init/cloud-huawei-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
/usr/local/python3/bin/pip3.7 install -r /app/init/cloud-qcloud-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
/usr/local/python3/bin/pip3.7 install -r /app/init/cloud-ksyun-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
/usr/local/python3/bin/pip3.7 install -r /app/init/pip3-common-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
