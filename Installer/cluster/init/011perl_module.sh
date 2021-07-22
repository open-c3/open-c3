#!/bin/bash 
set -e

cd /data/Software/mydan

/data/Software/mydan/perl/bin/perl -e 'use Dancer' || /data/Software/mydan/perl/bin/cpan install Dancer
/data/Software/mydan/perl/bin/cpan install Dancer::Plugin::Database

/data/Software/mydan/perl/bin/cpan  install Logger::Syslog

yum install perl-DBD-MySQL.x86_64 -y
yum install mysql-devel -y

/data/Software/mydan/perl/bin/cpan  install DBD::mysql

/data/Software/mydan/perl/bin/cpan install Twiggy
/data/Software/mydan/perl/bin/perl -e 'use Dancer2' || /data/Software/mydan/perl/bin/cpan install Dancer2

/data/Software/mydan/perl/bin/cpan install Dancer2::Plugin::WebSocket

/data/Software/mydan/perl/bin/cpan install LWP::Protocol::https

/data/Software/mydan/perl/bin/cpan install Mail::Sender
sed -i 's/warnings::warnif(/#warnings::warnif(/' /data/Software/mydan/perl/lib/site_perl/5.24.0/Mail/Sender.pm
