#!/bin/bash

if [ -f /opt/mydan/.lock ]; then
    echo "The mydan is locked"
    exit;
fi

#export MYDAN_REPO_PUBLIC="http://180.153.186.60 http://223.166.174.60"
#MYDAN_REPO_PRIVATE

OS=$(uname)
ARCH=$(uname -m)

if [ "X$OS" == "XDarwin" ] && [ "X$ARCH" == "Xx86_64" ]; then
    echo OS=$OS

    set -e
    mkdir -p /opt/mydan 
    cd /opt/mydan

    set +e
    cpan install Types::Standard

    perl -e 'use Types::Standard' 2>/dev/null

    if [ "X$?" != "X0" ]; then
        set -e
        rm -rf Type-Tiny-1.004002.tar.gz Type-Tiny-1.004002

        wget https://cpan.metacpan.org/authors/id/T/TO/TOBYINK/Type-Tiny-1.004002.tar.gz
        tar -zxvf Type-Tiny-1.004002.tar.gz
        cd Type-Tiny-1.004002
        perl Makefile.PL
        make
        make install

        rm -rf Type-Tiny-1.004002.tar.gz Type-Tiny-1.004002
    fi

    set -e
    cd /opt/mydan
    rm -rf mayi
    git clone https://github.com/MYDan/mayi.git
    cd mayi

    set +e
    for i in `cat Makefile.PL|grep ::|grep '=> \d'|awk '{print $1}'|sed "s/'//g"`; do
        echo "use $i"
        perl -e "use $i" 2>/dev/null || cpan install $i
    done

    set -e

    perl Makefile.PL
    make
    make install dan=1 box=1 def=1
    rm -rf /opt/mydan/mayi

else
    if [ "X$OPEN_C3_ADDR" == "X" ] ;then
        echo 'OPEN_C3_ADDR nofind'
        exit 1
    fi

    curl -L $OPEN_C3_ADDR/api/scripts/MYDan_perl_update.sh|bash || exit 1
    curl -L $OPEN_C3_ADDR/api/scripts/MYDan_mayi_update.sh|bash || exit 1

fi

echo mydan update OK
