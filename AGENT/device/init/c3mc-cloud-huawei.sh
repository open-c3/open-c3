#!/bin/bash

set -e

pip3.7 install huaweicloudsdkcore --upgrade

pip3.7 install huaweicloudsdkdcs huaweicloudsdkrds \
             huaweicloudsdkdds huaweicloudsdkecs huaweicloudsdkelb \
             huaweicloudsdkgaussdbfornosql huaweicloudsdkevs