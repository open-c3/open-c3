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
                    use Data::Dumper;
                    #my $code = $hdr->{Status} ||0;
                    #print Dumper $body;
                    $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::promNodeExporterMetrics = $body;
            }
            ;
        

    return ();
}

1;
