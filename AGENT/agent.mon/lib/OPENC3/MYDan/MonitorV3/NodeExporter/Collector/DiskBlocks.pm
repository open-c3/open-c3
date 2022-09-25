package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::DiskBlocks;

use strict;
use warnings;
use Carp;
use POSIX;

our %declare = (
    node_disk_blocks_use_percent => 'Disk usage percentage',
    node_disk_blocks_total => 'Total disk size',
    node_disk_blocks_free => 'Available size of disk',
);

our $collectorname = 'node_disk_blocks';
our $cmd = 'LANG=en df -l -T -P';

#Filesystem              Type     1024-blocks      Used Available Capacity Mounted on
#/dev/mapper/centos-root xfs         14034944  11865608   2169336      85% /
#devtmpfs                devtmpfs     8120964         0   8120964       0% /dev
sub co
{
    my @df = split /\n/, shift;
    my ( $error, @stat ) = ( 0 );
    eval{
        my $title = shift @df;
        die "df -l format unkown" unless $title =~ /^Filesystem\s+Type\s+1024-blocks\s+Used\s+Available\s+Capacity\s+Mounted on$/;
        for ( @df )
        {
            my ( $filesystem, $type, $total, $use, $free, $use_percent, $mountpoint ) = split /\s+/, $_, 7;
            next if $mountpoint =~ m#^/var/lib/docker/#;

            $use_percent =~ s/%//;
            my $lable = +{ mountpoint => $mountpoint, fstype => $type, filesystem => $filesystem };

            push @stat, +{
                name => 'node_disk_blocks_use_percent',
                value => $use_percent,
                lable => $lable,
            };
            push @stat, +{
                name => 'node_disk_blocks_total',
                value => $total,
                lable => $lable,
            };
            push @stat, +{
                name => 'node_disk_blocks_free',
                value => $free,
                lable => $lable,
            };
        }
    };
    if( $@ )
    {
        warn "collector node_disk_blocks_* err:$@";
        $error ++;
    }

    push @stat, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };
    return @stat;
}

1;
