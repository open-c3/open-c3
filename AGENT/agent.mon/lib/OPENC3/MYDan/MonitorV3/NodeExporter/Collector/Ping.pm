package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::Ping;

use strict;
use warnings;
use Carp;
use POSIX;
use Time::HiRes;
use OPENC3::MYDan::MonitorV3::NodeExporter::Collector;
use AnyEvent::Ping;

our %declare = (
    node_ping_delay => 'ping delay',
    node_ping_loss  => 'ping loss',
);

our $collectorname = 'node_ping';

my $ping = AnyEvent::Ping->new( timeout => 15 );

sub co
{
    my $extping = $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::extendedMonitor->{ping};

    my ( $error, @ping, @stat ) = ( 0 );
    @ping = @$extping if $extping && ref $extping eq 'ARRAY';

    for my $host ( @ping )
    {
        unless( $host && $host =~ /^[a-zA-Z\d][a-zA-Z\d\.\-_]+[a-zA-Z\d]$/ )
        {
            warn "ping host format error: $host";
            $error = 1;
            next;
        }

        my(  $sent_packets, $received, $timetotal ) = ( 3, 0, 0 );

        $ping->ping($host, $sent_packets, sub {
            my $results = shift;

            foreach my $result (@$results) {
                my ( $status, $time ) = @$result;
                if( $status && $status eq 'OK' )
                {
                    $timetotal += $time;
                    $received ++;
                }
            };

            my $delay = $received ? int(( $timetotal * 1000 ) / $received ): 60000;
            my $loss  = ( ( $sent_packets - $received ) / $sent_packets  ) * 100;
            $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::prom->set( 'node_ping_delay', $delay, +{ host => $host } );
            $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::prom->set( 'node_ping_loss',  $loss,  +{ host => $host } );

        });
    }

    push @stat, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };
    return @stat;
}

1;
