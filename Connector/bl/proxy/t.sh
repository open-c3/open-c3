#!/bin/bash
set -e

curl --location --request POST 'http://192.168.1.33:56383/run' \
--header 'Cache-Control: no-cache' \
--header 'Content-Type: application/json' \
--header 'AppName: xxxx' \
--header 'AppKey: zzzz' \
--data-raw '{
    "command": "jumpserver-bastion",
    "arguments": "{\"admin_user\": \"admin\", \"admin_pass\": \"ABCD.1234\", \"url\": \"http://192.168.1.33:80\", \"username\": \"test_wp\", \"email\": \"zhangsan@gmail.com\", \"ip\": \"192.168.1.34\", \"add_type\": \"1\"}"
}'
