package Util;
use warnings;
use strict;
use Carp;
use FindBin qw( $RealBin );

sub myname
{
    my $myname = `cat /etc/ci.myip`;
    chomp $myname if $myname;
    confess "no a ip in /etc/ci.myip" unless $myname && $myname =~ /^[a-zA-Z0-9\.\-]+$/;
    return $myname;
}

sub envinfo
{
    my %env;
    map{
        $env{$_} = `cat '$RealBin/../conf/$_'`;
        chomp $env{$_};
        die "load envinfo $_ fail" unless defined $env{$_} && $env{$_} =~ /^[a-zA-Z0-9\-\.]+$/;
    }@_;
    return %env;
}

1;
