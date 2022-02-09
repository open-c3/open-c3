package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::Uptime;

use strict;
use warnings;
use Carp;
use POSIX;
use Tie::File;

our %declare = (
    node_system_time => 'system time',
    node_system_uptime => 'system uptime',
);

our $collectorname = 'node_system_uptime';

sub co
{
    my ( $error, @stat ) = ( 0 );
    $error ++ unless tie my @temp, 'Tie::File', "/proc/uptime", mode => O_RDONLY, recsep => "\n";

    if( $temp[0] =~ /^(\d+\.*\d*)\s/ )
    {
        push @stat, +{ name => 'node_system_uptime', value => $1, };
    }
    else { $error ++; }

    push @stat, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };
    return @stat;
}

1;
