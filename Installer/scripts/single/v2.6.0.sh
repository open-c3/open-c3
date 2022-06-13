#!/bin/bash

docker exec -i openc3-server /data/Software/mydan/perl/bin/cpan install AnyEvent::HTTPD::Router AnyEvent::HTTPD::CookiePatch AnyEvent::HTTP

docker cp /data/open-c3/Installer/install-cache/bin/kubectl  openc3-server:/usr/bin/
docker cp /data/open-c3/Installer/install-cache/bin/yaml2json  openc3-server:/usr/bin/
docker cp /data/open-c3/Installer/install-cache/bin/json2yaml  openc3-server:/usr/bin/

#TODO 集群发布后，webshell容器需要拷贝kubectl命令到容器中，否则影响webshell进入pod。
#手动创建一个流水线，作为kubernetes管理的流水线默认模版。
#升级的时候可能会报错，确认CI模块的配置里面的端口是否被正确能让api.event生效。

docker cp /data/open-c3/CI/bin/aws_c3 openc3-server:/usr/local/bin/

docker cp /data/open-c3/lua/lualib/resty/http.lua openc3-lua:/usr/local/openresty/lualib/resty/http.lua
docker cp /data/open-c3/lua/lualib/resty/http_connect.lua openc3-lua:/usr/local/openresty/lualib/resty/http_connect.lua
docker cp /data/open-c3/lua/lualib/resty/http_headers.lua openc3-lua:/usr/local/openresty/lualib/resty/http_headers.lua

#oncall 需要的插件
docker exec -i openc3-server /data/Software/mydan/perl/bin/cpan install DateTime
mkdir -p /data/open-c3-data/glusterfs/oncall/{conf,data}

#mail mon
docker exec -i openc3-server /data/Software/mydan/perl/bin/cpan install Mail::POP3Client Email::MIME Email::MIME::RFC2047::Decoder
mkdir -p /data/open-c3-data/glusterfs/mailmon/{conf,data,run}

mkdir -p /data/open-c3-data/monitor-sender

#update webshell
cp /data/open-c3/web-shell/private/tty.js/static/tty.js /data/open-c3/web-shell/node_modules/tty.js/static/tty.js

#localbash

localbash=$(docker ps|grep [o]penc3-localbash|wc -l)
if [ "X$localbash" == "X0" ];then
    localbash=$(docker ps -a|grep [o]penc3-localbash|wc -l)
    if [ "X$localbash" == "X0" ];then
        docker run -d --name  openc3-localbash centos:7 sleep 999999999
    else
        docker start openc3-localbash
    fi
else
    echo localbash ok
fi

mkdir -p /data/open-c3-data/logs/CI/webhooks_data
mkdir -p /data/open-c3-data/logs/CI/webhooks_logs

docker exec -i openc3-server /data/Software/mydan/perl/bin/cpan install Paws Hash::Flatten

docker exec -i openc3-server touch /etc/openc3.supervisormin.on

mkdir -p /data/open-c3-data/cloudmon
if [ ! -f /data/open-c3-data/cloudmon/docker-compose ]; then
    cp /data/open-c3/Installer/docker-compose /data/open-c3-data/cloudmon/docker-compose 
    chmod +x /data/open-c3-data/cloudmon/docker-compose
fi

docker exec -i openc3-server /data/Software/mydan/perl/bin/cpan install Net::LDAP
