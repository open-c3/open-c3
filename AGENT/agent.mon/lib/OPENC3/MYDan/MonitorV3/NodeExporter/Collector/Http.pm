package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::Http;

use strict;
use warnings;
use Carp;
use POSIX;
use AnyEvent::HTTP;
use OPENC3::MYDan::MonitorV3::NodeExporter::Collector;
use OPENC3::MYDan::MonitorV3::NodeExporter;

our %declare = (
    node_http_code => 'http code',
    node_http_content_check => 'http content check',
);

our $collectorname = 'node_http';

sub co
{
    my $exthttp = $OPENC3::MYDan::MonitorV3::NodeExporter::extendedMonitor->{http};
    my ( $error, @http, @stat ) = ( 0 );
    @http = @$exthttp if $exthttp && ref $exthttp eq 'ARRAY';

    for my $http ( @http )
    {
        my @check = split /\|/, $http;
        if ( @check < 2 ) { $error = 1; next; }

        http_request
        $check[0] => $check[1],
        headers => { "user-agent" => "MYDan Monitor" },
        timeout => 10,
        sub {
            my ($body, $hdr) = @_;
                my $code = $hdr->{Status} ||0;
                $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::prom->
                    set( 'node_http_code', $code, +{ method => $check[0], url => $check[1] } );
                 
                $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::prom->
                    set( 'node_http_content_check', $body =~ /$check[2]/ ? 1 : 0, +{ method => $check[0], url => $check[1], check => $check[2] } )
                        if defined $check[2];
        };
    }

    push @stat, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };
    return @stat;
}

1;
