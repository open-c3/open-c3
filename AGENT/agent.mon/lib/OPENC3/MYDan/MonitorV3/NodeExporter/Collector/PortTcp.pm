package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::PortTcp;

use strict;
use warnings;
use Carp;
use POSIX;
use OPENC3::MYDan::MonitorV3::NodeExporter::Collector;

our %declare = (
    node_port => 'port monitor.',
);

our $collectorname = 'node_port_tcp';
our $cmd = 'LANG=en ss -t -l -n';

sub co
{
    my @ss = split /\n/, shift;
    my $extport = $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::extendedMonitor->{port};

    my @port;
    if( $extport && $extport->{tcp} && ref $extport->{tcp} eq 'ARRAY' )
    {
        @port = grep{ /^\d+$/ || /^\d+;[a-zA-Z0-9][a-zA-Z0-9\.\-_]+$/ }@{$extport->{tcp}};
    }
    return ( +{ name => 'node_collector_error', value => 0, lable => +{ collector => $collectorname } } ) unless @port;
    my ( $error, @stat ) = ( 0 );
    eval{
        my $title = shift @ss;
        die "ss format unkown" unless $title =~ /^State\s+Recv-Q\s+Send-Q\s+Local Address:Port\s+Peer Address:Port/;
        my %port;

        for ( @ss )
        {
            my @s = split /\s+/, $_;
            next unless $s[3] && $s[3] =~ /:(\d+)$/;
            my $port = $1;
            $port{$port} ||= 1;
            $port{$port} = 2 if $s[3] eq "*:$port" || $s[3] eq ":::$port";
        }
        for my $port ( @port )
        {
            my @check = split /;/, $port;
            my $lable = +{ port => $check[0], protocol => 'tcp', app => $check[-1] };

            push @stat, +{
                name => 'node_port',
                value => $port{$check[0]} || 0,
                lable => $lable,
            };
        }
    };
    if( $@ )
    {
        warn "collector node_port_tcp err:$@";
        $error = 1;
    }

    push @stat, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };
    return @stat;
}

1;
