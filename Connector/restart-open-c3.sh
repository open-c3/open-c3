#!/bin/bash


cd /data/Software/mydan/Connector/tools && ./SetEnv -e test
cd /data/Software/mydan/Connector/tools && ./restart

sleep 10;

cd /data/Software/mydan/CI/tools && ./SetEnv -e test
cd /data/Software/mydan/CI/tools && ./restart

cd /data/Software/mydan/AGENT/tools && ./SetEnv -e test
cd /data/Software/mydan/AGENT/tools && ./restart

cd /data/Software/mydan/JOB/tools && ./SetEnv -e test
cd /data/Software/mydan/JOB/tools && ./restart

cd /data/Software/mydan/JOBX/tools && ./SetEnv -e test
cd /data/Software/mydan/JOBX/tools && ./restart

/data/Software/mydan/web-shell/tools/start

cp /data/Software/mydan/c3-front/nginxconf/open-c3.org.conf /etc/nginx/conf.d/
nginx -s reload
