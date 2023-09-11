#!/bin/bash

set -e

cd /data/Software/mydan/Connector/pp/device/crontab/ssl-certificate-expired-notify

user=$(c3mc-app-usrext @cmdb_notify_ssl_expired|egrep "^[a-zA-Z][a-zA-Z0-9@\-\._]+$"|xargs -n 1000)

if [ "X$user" == "X" ]; then
    exit
fi

./notify $user
