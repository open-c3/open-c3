#!/bin/bash

set -e

/data/Software/mydan/python3/bin/pip3 install pycrypto -U -i https://pypi.tuna.tsinghua.edu.cn/simple
/data/Software/mydan/python3/bin/pip3 install pycryptodome -U -i https://pypi.tuna.tsinghua.edu.cn/simple
/data/Software/mydan/python3/bin/pip3 install -r /app/init/cloud-aliyun-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
/data/Software/mydan/python3/bin/pip3 install -r /app/init/cloud-aws-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
/data/Software/mydan/python3/bin/pip3 install -r /app/init/cloud-google-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
/data/Software/mydan/python3/bin/pip3 install -r /app/init/cloud-huawei-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
/data/Software/mydan/python3/bin/pip3 install -r /app/init/cloud-qcloud-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
/data/Software/mydan/python3/bin/pip3 install -r /app/init/cloud-ksyun-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
/data/Software/mydan/python3/bin/pip3 install -r /app/init/cloud-ibm-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
/data/Software/mydan/python3/bin/pip3 install -r /app/init/pip3-common-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
