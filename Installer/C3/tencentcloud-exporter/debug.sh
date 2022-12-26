#!/bin/bash

docker run -it -p 9123:9123 -v /data/open-c3/Installer/C3/tencentcloud-exporter/qcloud.yml:/qcloud.yml openc3/tencentcloud-exporter:20221122
