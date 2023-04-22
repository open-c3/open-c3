package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::MYDanAgent;

use strict;
use warnings;
use Carp;
use POSIX;

our %declare = (
    node_mydan_agent_65111_pub => 'MYDan deploy agent pub',
);

our $collectorname = 'node_mydan_agent';
our $cmd = 'LANG=en ls /opt/mydan/etc/agent/auth';

sub co
{
    my @auth = split /\n/, shift;
    my ( $error, @stat ) = ( 0 );
    eval{
        for ( @auth )
        {
            next unless $_ =~ /^([a-zA-Z\d]+[a-zA-Z\d_\-\.]*[a-zA-Z\d]+)\.pub$/;
            my $lable = +{ name => $1 };

            push @stat, +{
                name => 'node_mydan_agent_65111_pub',
                value => 1,
                lable => $lable,
            };
        }
    };
    if( $@ )
    {
        warn "collector node_mydan_agent_* err:$@";
        $error ++;
    }

    push @stat, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };
    return @stat;
}

1;
