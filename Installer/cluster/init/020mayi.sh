#!/bin/bash
set -e

test -e /data/Software/mydan/dan && exit 

/data/Software/mydan/perl/bin/perl -e 'use MYDan' || /data/Software/mydan/perl/bin/cpan install MYDan

cd /data/Software/mydan/
rm -rf mayi

git clone https://github.com/mydan/mayi.git
cd mayi
/data/Software/mydan/perl/bin/perl Makefile.PL
make
make install dan=1 box=1 def=1

cd /data/Software/mydan/
rm -rf mayi
