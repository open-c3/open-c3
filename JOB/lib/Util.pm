package Util;
use warnings;
use strict;
use Carp;
use Time::HiRes qw( gettimeofday );
use FindBin qw( $RealBin );

sub myname
{
    my $myname = `cat /etc/job.myip`;
    chomp $myname if $myname;
    confess "no a ip in /etc/job.myip" unless $myname && $myname =~ /^[a-zA-Z0-9\.\-]+$/;
    return $myname;
}

sub deleteSuffix
{
    my ( $seconds, $microseconds ) = gettimeofday;
    POSIX::strftime( "%Y%m%d%H%M%S", localtime( $seconds ) ). sprintf "%03d", int $microseconds/1000;
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
