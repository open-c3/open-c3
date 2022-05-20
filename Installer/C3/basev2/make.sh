#!/bin/bash
set -e

yum -y install make gcc lsof psmisc wget 
#git
cd /tmp
wget http://opensource.wandisco.com/centos/7/git/x86_64/wandisco-git-release-7-1.noarch.rpm
rpm -ivh wandisco-git-release-7-1.noarch.rpm
yum install git -y

#perl
mkdir -p /data/Software/mydan
cd /data/Software/mydan
wget http://www.cpan.org/src/5.0/perl-5.24.0.tar.gz 
tar -zxvf perl-5.24.0.tar.gz 
rm -f perl-5.24.0.tar.gz 
cd /data/Software/mydan/perl-5.24.0 
./Configure -des -Dprefix=/data/Software/mydan/perl  -Dusethreads -Uinstalluserbinperl 
make 
make install 
rm -rf /data/Software/mydan/perl-5.24.0**

#nginx
#yum -y install nginx
yum -y install gcc gcc-c++ autoconf automake gd gd-devel zlib zlib-devel openssl openssl-devel pcre-devel
mkdir /root/nginx.install
cd /root/nginx.install
wget http://nginx.org/download/nginx-1.17.7.tar.gz
git clone https://github.com/hongzhidao/nginx-upload-module.git
git clone https://github.com/masterzen/nginx-upload-progress-module.git
tar -xzvf nginx-1.17.7.tar.gz 
cd nginx-1.17.7/

./configure  --with-debug --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --add-module=/root/nginx.install/nginx-upload-module --add-module=/root/nginx.install/nginx-upload-progress-module --with-stream --with-http_image_filter_module --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-file-aio --with-cc-opt='-Wno-format-security -Wno-unused-but-set-variable -Wno-unused-result -D NGX_HAVE_OPENSSL_MD5_H=1 -D NGX_OPENSSL_MD5=1 -D NGX_HAVE_OPENSSL_SHA1_H=1 -O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2  -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic'

make && make install

cd /
rm -rf /root/nginx.install

#perl module
yum -y install perl-DBD-MySQL.x86_64 mysql-devel 
/data/Software/mydan/perl/bin/cpan install Dancer 
/data/Software/mydan/perl/bin/cpan install Dancer::Plugin::Database 
/data/Software/mydan/perl/bin/cpan install Logger::Syslog 
/data/Software/mydan/perl/bin/cpan install DBD::mysql 
/data/Software/mydan/perl/bin/cpan install Twiggy 
/data/Software/mydan/perl/bin/cpan install Dancer2 
/data/Software/mydan/perl/bin/cpan install Dancer2::Plugin::WebSocket 
/data/Software/mydan/perl/bin/cpan install LWP::UserAgent
/data/Software/mydan/perl/bin/cpan install Time::TAI64
/data/Software/mydan/perl/bin/cpan install Crypt::PK::RSA
/data/Software/mydan/perl/bin/cpan install Net::IP::Match::Regexp
/data/Software/mydan/perl/bin/cpan install Data::Validate::IP
/data/Software/mydan/perl/bin/cpan install Expect
/data/Software/mydan/perl/bin/cpan install Authen::OATH
/data/Software/mydan/perl/bin/cpan install Convert::Base32
/data/Software/mydan/perl/bin/cpan install Term::ReadKey
/data/Software/mydan/perl/bin/cpan install Data::UUID
/data/Software/mydan/perl/bin/cpan install Term::Size
/data/Software/mydan/perl/bin/cpan install Term::Completion
/data/Software/mydan/perl/bin/cpan install DBD::SQLite
/data/Software/mydan/perl/bin/cpan install LWP::Protocol::https
/data/Software/mydan/perl/bin/cpan install AnyEvent::HTTPD::Router AnyEvent::HTTPD::CookiePatch AnyEvent::HTTP
/data/Software/mydan/perl/bin/cpan install DateTime
/data/Software/mydan/perl/bin/cpan install Mail::POP3Client Email::MIME Email::MIME::RFC2047::Decoder
/data/Software/mydan/perl/bin/cpan install Paws

rm -rf /data/Software/mydan/perl/man
rm -rf /root/.cpan

#mydan
cd /data/Software/mydan 
git clone https://github.com/mydan/mayi.git 
cd /data/Software/mydan/mayi 
/data/Software/mydan/perl/bin/perl Makefile.PL 
make 
make install dan=1 box=1 def=1 
rm -rf /data/Software/mydan/mayi 

#web-shell
yum -y install net-tools
cd /
wget https://nodejs.org/dist/v4.2.6/node-v4.2.6-linux-x64.tar.gz
tar -zxvf node-v4.2.6-linux-x64.tar.gz -C / 
ln -fsn /node-v4.2.6-linux-x64/bin/node  /usr/bin/node
ln -fsn /node-v4.2.6-linux-x64/bin/npm  /usr/bin/npm
yum install -y vixie-cron crontabs

rm /node-v4.2.6-linux-x64.tar.gz 

# awscli
yum install -y unzip && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
/aws/install
rm -rf /aws /awscliv2.zip

#mysql
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
wget -i -c http://dev.mysql.com/get/mysql57-community-release-el7-10.noarch.rpm
yum -y install mysql57-community-release-el7-10.noarch.rpm
yum -y install mysql-community-server

rm mysql57-community-release-el7-10.noarch.rpm
rm /usr/sbin/mysqld-debug
rm /usr/bin/mysqlbinlog
rm /usr/bin/mysql_upgrade
rm /usr/bin/mysql_config_editor
rm /usr/bin/myisam_ftdump
rm /usr/bin/myisamchk
rm /usr/bin/myisamlog
rm /usr/bin/myisampack

rm -rf /usr/lib64/mysql/mecab
rm -rf /usr/lib64/mysql/plugin/debug

#clean
yum clean all
