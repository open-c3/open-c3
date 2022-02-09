package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::PortUdp;

use strict;
use warnings;
use Carp;
use POSIX;
use OPENC3::MYDan::MonitorV3::NodeExporter;

our %declare = (
    node_port => 'port monitor.',
);

our $collectorname = 'node_port_udp';
our $cmd = 'LANG=en ss -u -a -n';

sub co
{
    my @ss = split /\n/, shift;
    my $extport = $OPENC3::MYDan::MonitorV3::NodeExporter::extendedMonitor->{port};

    my @port;
    if( $extport && $extport->{udp} && ref $extport->{udp} eq 'ARRAY' )
    {
        @port = grep{ /^\d+$/ }@{$extport->{udp}};
    }
    return () unless @port;
    my ( $error, @stat ) = ( 0 );
    eval{
        my $title = shift @ss;
        die "ss format unkown" unless $title =~ /^State\s+Recv-Q\s+Send-Q\s+Local Address:Port\s+Peer Address:Port/;
        my %port;

        for ( @ss )
        {
            my @s = split /\s+/, $_;
            next unless $s[3] && $s[3] =~ /\*:(\d+)/;
            $port{$1} ++;
        }
        for my $port ( @port )
        {
            my $lable = +{ port => $port, protocol => 'udp' };

            push @stat, +{
                name => 'node_port',
                value => $port{$port} || 0,
                lable => $lable,
            };
        }
    };
    if( $@ )
    {
        warn "collector node_port_udp err:$@";
        $error ++;
    }

    push @stat, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };
    return @stat;
}

1;
