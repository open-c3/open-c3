#!/bin/bash

set -e

pip3 install huaweicloudsdkcore --upgrade

pip3 install huaweicloudsdkdcs huaweicloudsdkrds \
             huaweicloudsdkdds huaweicloudsdkecs huaweicloudsdkelb \
             huaweicloudsdkgaussdbfornosql huaweicloudsdkevs