package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::PromeNodeExporter;

use strict;
use warnings;
use Carp;
use POSIX;
use AnyEvent::HTTP;
use OPENC3::MYDan::MonitorV3::NodeExporter::Collector;
use OPENC3::MYDan::MonitorV3::NodeExporter;

our %declare = ();

sub co
{
    http_request
    'GET' => 'http://127.0.0.1:9100/metrics',
    headers => { "user-agent" => "MYDan Monitor" },
    timeout => 10,
    sub {
        my ($body, $hdr) = @_;
            my $code = $hdr->{Status} ||0;
            my $metrics = "";
            if( $code eq '200' )
            {
                $metrics = $body;
                $metrics .= "\nnode_collector_error{collector=\"prome_node_exporter\"} 0";
            }
            else
            {
                $metrics = "";
                $metrics .= "\nnode_collector_error{collector=\"prome_node_exporter\"} 1";
            }

            $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::promNodeExporterMetrics = $metrics;
    };

    return ();
}

1;
