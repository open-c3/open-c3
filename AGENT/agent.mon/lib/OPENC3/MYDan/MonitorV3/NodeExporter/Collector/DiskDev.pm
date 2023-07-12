package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::DiskDev;

use strict;
use warnings;
use Carp;
use POSIX;

our %declare = (
    node_disk_dev_use_percent => 'Disk dev usage percentage',
);

our $collectorname = 'node_disk_dev';
our $cmd = '/opt/mydan/dan/agent.mon/bin/node_disk_dev_use_percent';

sub co
{
    my @df = split /\n/, shift;
    my ( $error, @stat ) = ( 0 );
    eval{
        for ( @df )
        {
            my ( $dev, $realname, $percent ) = split /\s+/, $_, 3;
            next unless $percent =~ m#^\d[\d\.]*#;

            push @stat, +{
                name => 'node_disk_dev_use_percent',
                value => $percent,
                lable => +{ dev => $dev, realname => $realname },
            };
        }
    };
    if( $@ )
    {
        warn "collector node_disk_dev_* err:$@";
        $error ++;
    }

    push @stat, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };
    return @stat;
}

1;
