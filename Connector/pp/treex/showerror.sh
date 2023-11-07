#!/bin/bash
cat error.log |grep -v ';domain;'|grep -v ';aws-rds-snapshot;'|grep -v ';storage-resource;'|grep -v ';huawei'|grep -v ';ssl-certificate;'|grep -v ';networking;'
