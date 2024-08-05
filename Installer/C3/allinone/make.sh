#!/bin/bash

set -e

mkdir -p /data/logs/JOB
mkdir -p /data/glusterfs/fileserver
mkdir -p /data/logs/JOBX
mkdir -p /data/logs/AGENT
mkdir -p /etc/cron.d.root
mkdir -p /data/logs/CI
mkdir -p /data/glusterfs/ci_repo

#cd /tmp
#rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
#wget -i -c http://dev.mysql.com/get/mysql57-community-release-el7-10.noarch.rpm
#yum -y install mysql57-community-release-el7-10.noarch.rpm
#yum -y install mysql-community-server

mysqld --initialize --user=mysql --datadir=/var/lib/mysql

cp /my.cnf /etc/my.cnf

ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo 'Asia/Shanghai' >/etc/timezone

#/data/Software/mydan/perl/bin/cpan install AnyEvent::HTTPD::Router AnyEvent::HTTPD::CookiePatch AnyEvent::HTTP
#/data/Software/mydan/perl/bin/cpan install DateTime
#/data/Software/mydan/perl/bin/cpan install Mail::POP3Client Email::MIME Email::MIME::RFC2047::Decoder
#rm -rf /data/Software/mydan/perl/man
#rm -rf /root/.cpan

mkdir -p /data/open-c3-data

#clean
#yum clean all

date >> /etc/openc3.supervisormin.on
date >> /etc/openc3.allinon

tar zxf /prometheus.tar.gz -C /usr
mv /usr/prometheus-2.37.2.linux-amd64 /usr/prometheus

tar zxf /alertmanager.tar.gz -C /usr
mv /usr/alertmanager-0.27.0.linux-386 /usr/alertmanager

cp /data/Software/mydan/lua/config/lua-for-allinone.conf /etc/nginx/conf.d/
