#!/bin/bash

X=$(docker inspect openc3-lua 2>&1|grep Created|wc -l)

if [ "X1" == "X$X"  ]; then
    docker start openc3-lua
else
    IMAGE='openresty/openresty:1.9.15.1-trusty'
    docker run -d --name="openc3-lua"\
        -p 2345:80 \
        -v /data/open-c3/lua/config/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf:ro \
        -v /data/open-c3/lua/config/lua:/usr/local/openresty/nginx/conf/lua:ro \
        -v /data/open-c3-data/logs/lua:/usr/local/openresty/nginx/logs \
        -v /data/open-c3/lua/lualib/resty/http.lua:/usr/local/openresty/lualib/resty/http.lua \
        -v /data/open-c3/lua/lualib/resty/http_connect.lua:/usr/local/openresty/lualib/resty/http_connect.lua \
        -v /data/open-c3/lua/lualib/resty/http_headers.lua:/usr/local/openresty/lualib/resty/http_headers.lua \
        $IMAGE
fi
