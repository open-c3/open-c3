#!/bin/bash

set -e

wget -c http://luajit.org/download/LuaJIT-2.0.4.tar.gz
tar -xzvf LuaJIT-2.0.4.tar.gz
cd LuaJIT-2.0.4
make install PREFIX=/opt/luajit

cd /opt/
wget https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz
tar -xzvf v0.3.0.tar.gz

cd /opt
wget https://github.com/openresty/lua-nginx-module/archive/v0.10.8.tar.gz
tar -xzvf v0.10.8.tar.gz

cd /opt
wget http://nginx.org/download/nginx-1.10.3.tar.gz
tar -xzvf nginx-1.10.3.tar.gz
export LUAJIT_LIB=/opt/luajit/lib
export LUAJIT_INC=/opt/luajit/include/luajit-2.0
cd nginx-1.10.3
./configure --prefix=/opt/nginx --with-http_stub_status_module --with-http_gzip_static_module --with-http_realip_module --with-http_sub_module --with-http_ssl_module --add-module=/opt/ngx_devel_kit-0.3.0 --add-module=/opt/lua-nginx-module-0.10.8

make -j2
make install

echo "/opt/luajit/lib" >> /etc/ld.so.conf
ldconfig

sed -i 's/ 80;/ 8234;/' /opt/nginx/conf/nginx.conf
