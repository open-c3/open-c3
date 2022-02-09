package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::PromeNodeExporter;

use strict;
use warnings;
use Carp;
use POSIX;
use AnyEvent::HTTP;
use OPENC3::MYDan::MonitorV3::NodeExporter::Collector;

our %declare = ();

our $collectorname = 'node_exporter_prome'; #TODO

sub co
{
    http_request
    'GET' => 'http://127.0.0.1:9100/metrics',
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

        $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::promNodeExporterMetrics = $metrics;
        $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::promeerror = $promeerror;
    };

    return ();
}

1;
