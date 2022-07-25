#!/bin/bash
set -x 
nameserver=$(cat /etc/resolv.conf |grep nameserver | awk '{print $2}'|egrep "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"|head -n 1)

if [ "X$nameserver" != "X" ];then
    #没有目录权限,直接sed -i会报错，这里使用临时文件的方式
    sed "s/resolver [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*/resolver $nameserver/" /usr/local/openresty/nginx/conf/nginx.conf > /tmp/nginx.conf.temp.$$
    cp /tmp/nginx.conf.temp.$$ /usr/local/openresty/nginx/conf/nginx.conf
    rm /tmp/nginx.conf.temp.$$
fi

cp /lualib/resty/http.lua         /usr/local/openresty/lualib/resty/http.lua
cp /lualib/resty/http_connect.lua /usr/local/openresty/lualib/resty/http_connect.lua
cp /lualib/resty/http_headers.lua /usr/local/openresty/lualib/resty/http_headers.lua

exec /usr/local/openresty/nginx/sbin/nginx -g "daemon off;"
