package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::ServiceDiscovery;

use strict;
use warnings;
use Carp;
use POSIX;

our %declare = (
    node_service_discovery => 'service_discovery',
);

our $collectorname = 'node_service_discovery';
our $cmd = 'LANG=en ps -eo comm,cmd';
#
# LANG=en ps -eo comm,cmd
# COMMAND         CMD
# systemd         /usr/lib/systemd/systemd --switched-root --system --deserialize 22
# kthreadd        [kthreadd]
# ksoftirqd/0     [ksoftirqd/0]
# kworker/0:0H    [kworker/0:0H]
# migration/0     [migration/0]
# rcu_bh          [rcu_bh]
# rcu_sched       [rcu_sched]

sub co
{
    my @ps = split /\n/, shift;
    my ( $error, @stat ) = ( 0 );

    my %uniq;
    eval{
        my $title = shift @ps;
        die "ps format unknown" unless $title =~ /^COMMAND\s+CMD$/;
        for ( @ps )
        {
            my ( $name, $cmd ) = split /\s+/, $_, 2;

            my $subname;
            $subname = ( $cmd =~ /\-jar\s+([a-zA-Z0-9\.\-_\/]+)\b/ ? $1 : 'unknown' ) if $name eq 'java';
            $subname = 'nginx' if $name eq 'nginx';

            next unless $subname;

            next if $uniq{$name}{$subname} ++;

            my $lable = +{ name => $name, subname => $subname };

            push @stat, +{
                name => 'node_service_discovery',
                value => 1,
                lable => $lable,
            };
        }
    };
    if( $@ )
    {
        warn "collector node_service_discovery_* err:$@";
        $error ++;
    }

    push @stat, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };
    return @stat;
}

1;
