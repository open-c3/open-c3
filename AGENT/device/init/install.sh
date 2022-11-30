#!/bin/bash

set -e

/data/Software/mydan/AGENT/device/init/install-python2.sh
/data/Software/mydan/AGENT/device/init/install-pip.sh
/data/Software/mydan/AGENT/device/init/install-python3.sh

pip3 install pycrypto -U -i https://pypi.tuna.tsinghua.edu.cn/simple
pip3 install pycryptodome -U -i https://pypi.tuna.tsinghua.edu.cn/simple

pip3 install -r /data/Software/mydan/AGENT/device/init/cloud-aliyun-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
pip3 install -r /data/Software/mydan/AGENT/device/init/cloud-aws-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
pip3 install -r /data/Software/mydan/AGENT/device/init/cloud-google-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
pip3 install -r /data/Software/mydan/AGENT/device/init/cloud-huawei-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
pip2 install -r /data/Software/mydan/AGENT/device/init/cloud-ksyun-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
pip3 install -r /data/Software/mydan/AGENT/device/init/cloud-qcloud-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
pip3 install -r /data/Software/mydan/AGENT/device/init/pip3-common-requrements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple