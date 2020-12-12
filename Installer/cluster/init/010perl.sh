#!/bin/bash 
set -e

cd /data/Software/mydan

./perl/bin/perl -V >/dev/null 2>&1 && exit 0

if [ -f /data/Software/mydan/Installer/install-cache/perl.tar.gz ];then
    tar -zxvf /data/Software/mydan/Installer/install-cache/perl.tar.gz -C /data/Software/mydan
fi

./perl/bin/perl -V >/dev/null 2>&1 && exit 0

rm -rf perl-5.24.0 perl-5.24.0.tar.gz

wget http://www.cpan.org/src/5.0/perl-5.24.0.tar.gz
tar -zxvf perl-5.24.0.tar.gz

cd perl-5.24.0

./Configure -des -Dprefix=/data/Software/mydan/perl  -Dusethreads -Uinstalluserbinperl
make
make test
make install

cd /data/Software/mydan

rm -rf perl-5.24.0 perl-5.24.0.tar.gz
