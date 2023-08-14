#!/bin/bash

set -e 

INSTALLERDIR='/opt/mydan'
#PERLVERSION=5.24.0
#有的aarch64的系统需要使用">=5.32.1"的版本。
PERLVERSION=5.32.1

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


while read -r i;do
    echo "use $i"
    /opt/mydan/perl/bin/perl -e "use $i" 2>/dev/null || /opt/mydan/perl/bin/cpan install $i
done <<EOF
YAML::XS
DBD::SQLite
Getopt::Long
Thread::Queue
IO::Socket::Multicast
Term::ANSIColor
Time::TAI64
Crypt::PK::RSA
Term::Completion
Data::UUID
Time::HiRes
Compress::Zlib
Crypt::PK::RSA
LWP::UserAgent
IO::Stty
Term::ReadKey
IO::Poll
AnyEvent::HTTP
AnyEvent::Handle
AnyEvent::Socket
AnyEvent::Impl::Perl
IO::Pty
Term::Size
File::Temp
Authen::OATH
Convert::Base32
Net::IP::Match::Regexp
Data::Validate::IP
LWP::Protocol::https
List::MoreUtils
Module::Runtime
URI::Escape
Filesys::Df
AnyEvent::Ping
EOF

echo "INSTALL Perl: SUCCESS!!!"
