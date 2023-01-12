#!/bin/bash

# 查询证书列表
echo '{"account": "openc3test"}' | c3mc-qcloud-clb-describe-cert-list | c3mc-bpm-display-field-values CertificateId,Domain
