#!/bin/bash
set -ex

/data/Software/mydan/perl/bin/cpan install Net::LDAP
/data/Software/mydan/perl/bin/cpan install Crypt::RC4::XS
/data/Software/mydan/perl/bin/cpan install Email::Sender::Simple
/data/Software/mydan/perl/bin/cpan install Email::Sender::Transport::SMTPS
/data/Software/mydan/perl/bin/cpan install Auth::GoogleAuth
/data/Software/mydan/perl/bin/cpan install MIME::Words
/data/Software/mydan/perl/bin/cpan install AnyEvent::Ping
/data/Software/mydan/perl/bin/cpan install Net::DNS::Dig
/data/Software/mydan/perl/bin/cpan install AnyEvent::HTTPD::Router
/data/Software/mydan/perl/bin/cpan install AnyEvent::HTTPD::CookiePatch

rm -rf /data/Software/mydan/perl/man
rm -rf /root/.cpan

cd /data/Software/mydan
tar -zcf perl.tar.gz perl
