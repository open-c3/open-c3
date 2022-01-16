#!/bin/bash

#该版本从v2.3.5升级过来，没有修改任何数据库表结构。
#该脚本用于从v2.2.0升级到v2.4.0
#初始化脚本应该包含v2.3.1-v2.3.5的集合。

docker exec -i c3_openc3-server_1 /data/Software/mydan/perl/bin/cpan install AnyEvent::HTTPD::Router AnyEvent::HTTPD::CookiePatch

docker cp /data/open-c3/Installer/install-cache/bin/kubectl  c3_openc3-server_1:/usr/bin/
docker cp /data/open-c3/Installer/install-cache/bin/yaml2json  c3_openc3-server_1:/usr/bin/
docker cp /data/open-c3/Installer/install-cache/bin/json2yaml  c3_openc3-server_1:/usr/bin/

#TODO 集群发布后，webshell容器需要拷贝kubectl命令到容器中，否则影响webshell进入pod。
#手动创建一个流水线，作为kubernetes管理的流水线默认模版。
#升级的时候可能会报错，确认CI模块的配置里面的端口是否被正确能让api.event生效。
