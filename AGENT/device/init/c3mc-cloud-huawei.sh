#!/bin/bash

set -e

pip3 uninstall -y huaweicloudsdkcore

pip3 install huaweicloudsdkcore huaweicloudsdkdcs huaweicloudsdkrds \
             huaweicloudsdkdds huaweicloudsdkecs huaweicloudsdkelb \
             huaweicloudsdkgaussdbfornosql huaweicloudsdkevs