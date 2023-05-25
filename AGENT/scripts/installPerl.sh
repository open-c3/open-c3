#!/bin/bash

set -e 

INSTALLERDIR='/opt/mydan'
PERLVERSION=5.24.0

checktool() {
    if ! type $1 >/dev/null 2>&1; then
        echo "Need tool: $1"
        exit 1;
    fi
}

checktool wget
checktool make
checktool gcc

mkdir -p $INSTALLERDIR
cd $INSTALLERDIR
wget http://www.cpan.org/src/5.0/perl-$PERLVERSION.tar.gz

tar -zxvf perl-$PERLVERSION.tar.gz
rm -f perl-$PERLVERSION.tar.gz

cd $INSTALLERDIR/perl-$PERLVERSION
./Configure -des -Dprefix=$INSTALLERDIR/perl  -Dusethreads -Uinstalluserbinperl

make
#make test #TODO
make install

rm -rf /opt/mydan/perl-5.24.0*
