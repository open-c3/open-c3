#!/bin/bash
set -e

gcc -v >/dev/null 2>&1 || yum install gcc -y
git --version >/dev/null 2>&1 || yum install git -y
mysql -V >/dev/null 2>&1 || yum install mysql -y

rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm || echo 
nginx -v >/dev/null 2>&1 || yum install nginx -y

lsof -v >/dev/null 2>&1 || yum install lsof -y
killall -V >/dev/null 2>&1 ||yum install psmisc -y

#ci
svn --version >/dev/null 2>&1 || yum install svn -y
docker -v  >/dev/null 2>&1 || curl -fsSL https://get.docker.com | bash
service docker start
