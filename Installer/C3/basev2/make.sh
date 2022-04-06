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
yum -y install nginx

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

#clean
yum clean all
