package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::FalconMigrate;

use strict;
use warnings;
use Carp;
use POSIX;
use AnyEvent::HTTP;
use Time::HiRes;
use OPENC3::MYDan::MonitorV3::NodeExporter::Collector;

our %declare = (
    falcon_migrate_version => 'FalconMigrate Version',
    falcon_migrate_accepts => 'FalconMigrate Accepts',
    falcon_migrate_error   => 'FalconMigrate Error',
);

our $collectorname = 'falcon_migrate';

sub co
{
    unless( -f '/opt/mydan/dan/bootstrap/exec/mydan.falcon_migrate.1988' )
    {
        $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::prom->set( 'falcon_migrate_version', -1 );
        $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::prom->set( 'falcon_migrate_accepts', -1 );
        $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::prom->set( 'falcon_migrate_error',   -1   );
        return ( +{ name => 'node_collector_error', value => 0, lable => +{ collector => $collectorname } } );
    }

    http_request
        'GET' => 'http://127.0.0.1:1988/status/',
        timeout => 10,
        sub {
            my ($body, $hdr) = @_;
            my ( $version, $accepts, $error ) = ( 0, -1, -1 );
            if( $hdr->{Status} && $hdr->{Status} eq '200' )
            {
                $version = $1 if $body =~ /version: (\d+)/;
                $accepts = $1 if $body =~ /accepts: (\d+)/;
                $error   = $1 if $body =~ /error: (\d+)/;
            }
            $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::prom->set( 'falcon_migrate_version', $version );
            $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::prom->set( 'falcon_migrate_accepts', $accepts );
            $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::prom->set( 'falcon_migrate_error',   $error   );
                 
        };

    return ( +{ name => 'node_collector_error', value => 0, lable => +{ collector => $collectorname } } );
}

1;
