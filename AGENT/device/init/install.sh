#!/bin/bash

set -e

/data/Software/mydan/AGENT/device/init/install-python2.sh
/data/Software/mydan/AGENT/device/init/install-pip.sh
/data/Software/mydan/AGENT/device/init/install-python3.sh

pip3 install pycrypto -U
pip3 install pycryptodome -U

pip3 install -r /data/Software/mydan/AGENT/device/init/cloud-aliyun-requrements.txt
pip3 install -r /data/Software/mydan/AGENT/device/init/cloud-aws-requrements.txt
pip3 install -r /data/Software/mydan/AGENT/device/init/cloud-google-requrements.txt
pip3 install -r /data/Software/mydan/AGENT/device/init/cloud-huawei-requrements.txt
pip2 install -r /data/Software/mydan/AGENT/device/init/cloud-ksyun-requrements.txt
pip3 install -r /data/Software/mydan/AGENT/device/init/cloud-qcloud-requrements.txt
pip3 install -r /data/Software/mydan/AGENT/device/init/pip3-common-requrements.txt