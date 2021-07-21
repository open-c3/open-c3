#!/bin/bash

if [ "X$1" == "Xreload" ];then
    set -e
    /data/Software/mydan/Connector/tools/reload
    /data/Software/mydan/CI/tools/reload
    /data/Software/mydan/AGENT/tools/reload
    /data/Software/mydan/JOB/tools/reload
    /data/Software/mydan/JOBX/tools/reload

    echo open-c3 reload done.
    exit;
fi

CTRL=restart

if [ "X$1" == "Xstart" ];then
    CTRL=start
fi

cd /data/Software/mydan/CI/tools && ./SetEnv -e test
cd /data/Software/mydan/AGENT/tools && ./SetEnv -e test
cd /data/Software/mydan/JOB/tools && ./SetEnv -e test
cd /data/Software/mydan/JOBX/tools && ./SetEnv -e test

cd /data/Software/mydan/Connector/tools && ./SetEnv -e test
cd /data/Software/mydan/Connector/tools && ./$CTRL

sleep 10;

cd /data/Software/mydan/CI/tools && ./SetEnv -e test
cd /data/Software/mydan/AGENT/tools && ./SetEnv -e test
cd /data/Software/mydan/JOB/tools && ./SetEnv -e test
cd /data/Software/mydan/JOBX/tools && ./SetEnv -e test

cd /data/Software/mydan/CI/tools && ./$CTRL
cd /data/Software/mydan/AGENT/tools && ./$CTRL
cd /data/Software/mydan/JOB/tools && ./$CTRL
cd /data/Software/mydan/JOBX/tools && ./$CTRL

/data/Software/mydan/web-shell/tools/start

cp /data/Software/mydan/c3-front/nginxconf/open-c3.org.conf /etc/nginx/conf.d/
nginx -s reload

echo open-c3 $CTRL done.
