package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::PromeNodeExporter;

use strict;
use warnings;
use Carp;
use POSIX;
use AnyEvent::HTTP;
use OPENC3::MYDan::MonitorV3::NodeExporter::Collector;

our %declare = ();

our $collectorname = 'node_exporter_prome'; #TODO

my $promeip;

BEGIN{
    $promeip = '127.0.0.1';
    my @x = `netstat -nlpt|grep :9100|grep node_exporter`;
    chomp @x;
    for ( @x )
    {
        if( $_ =~ /\s+(\d+\.\d+\.\d+\.\d+):9100\s+/ )
        {
            $promeip = $1 unless $1 eq '0.0.0.0';
        }
    }
};

sub co
{
    http_request
    'GET' => "http://$promeip:9100/metrics",
    headers => { "user-agent" => "MYDan Monitor" },
    timeout => 10,
    sub {
        my ($body, $hdr) = @_;
        my ( $metrics, $promeerror ) = ( "", 1 );
        if( $hdr->{Status} && $hdr->{Status} eq '200' )
        {
            $metrics = $body;
            $promeerror = 0;
        }

        $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::promelocal = $metrics;
        $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::promeerror = $promeerror;
    };

    return ();
}

1;
