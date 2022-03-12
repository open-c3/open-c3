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
/data/Software/mydan/perl/bin/cpan install DateTime
