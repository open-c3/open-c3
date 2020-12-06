package Util;
use warnings;
use strict;
use Carp;
use FindBin qw( $RealBin );

sub myname
{
    my $myname = `cat /etc/agent.myip`;
    chomp $myname if $myname;
    confess "no a ip in /etc/agent.myip" unless $myname && $myname =~ /^[a-zA-Z0-9\.\-]+$/;
    return $myname;
}

our %reason = (
    'service not known' => 'Service not known',
    'Permission denied' => 'Permission denied',
    'MYDan auth fail' => 'Agent auth fail',
    'Connection timed out' => 'Connection timed out',
    'No route to host' => 'No route to host',
    'password fromat error' => 'Unsupported characters in password',
);

sub envinfo
{
    my %env;
    map{
        $env{$_} = `cat '$RealBin/../conf/$_'`;
        chomp $env{$_};
        die "load envinfo $_ fail" unless defined $env{$_} && $env{$_} =~ /^[a-zA-Z0-9\.]+$/;
    }@_;
    $env{appkey} = $ENV{OPEN_C3_RANDOM} if $env{appkey} && $env{appkey} eq 'c3random' && $ENV{OPEN_C3_RANDOM};
    return %env;
}
1;
