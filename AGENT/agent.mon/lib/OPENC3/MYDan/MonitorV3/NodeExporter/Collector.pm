package OPENC3::MYDan::MonitorV3::NodeExporter::Collector;

use warnings;
use strict;
use Carp;
use IPC::Open3;
use Symbol 'gensym';
use AnyEvent;

use OPENC3::MYDan::MonitorV3::Prometheus::Tiny;

my %declare = (
    node_collector_error => 'Number of errors encountered during node exporter collection',
);

my %proc;
our $prom;
our $promNodeExporterMetrics;

sub new
{
    my ( $class, %this ) = @_;
    $prom = $this{prom} = OPENC3::MYDan::MonitorV3::Prometheus::Tiny->new;
    my @task = qw( DiskBlocks DiskInodes Uptime PortTcp PortUdp Process Http PromeNodeExporter Sar );

    my $i = 0;
    for my $type ( @task )
    {
        $i ++;
        eval "use OPENC3::MYDan::MonitorV3::NodeExporter::Collector::${type};";
        warn "err: $@" if $@;
        eval "%declare = ( %declare, %OPENC3::MYDan::MonitorV3::NodeExporter::Collector::${type}::declare );";
        warn "err: $@" if $@;

        my $collectorname;
        eval "\$collectorname = \$OPENC3::MYDan::MonitorV3::NodeExporter::Collector::${type}::collectorname;";
        warn "load collectorname fail: $@" if $@;
 
        $this{prom}->set( 'node_collector_error', -1, +{ collector => $collectorname } ) if $collectorname;

        my $cmd;
        eval "\$cmd = \$OPENC3::MYDan::MonitorV3::NodeExporter::Collector::${type}::cmd;";
        warn "load cmd fail: $@" if $@;
        if( $cmd )
        {

            $this{timer}{$type} = AnyEvent->timer(
                after => $i, 
                interval => 15,
                cb => sub {
                    return if $proc{$type}{pid};
                    my ( $err, $wtr, $rdr ) = gensym;
                    my $pid = IPC::Open3::open3( undef, $rdr, undef, $cmd );
                    $proc{$type}{pid} = $pid;
                    $proc{$type}{child} = AnyEvent->child(
                        pid => $pid, cb => sub{
                            delete $proc{$type}{pid};
                            my $input;my $n = sysread $rdr, $input, 102400;
                            return unless $n;

                            my @data = eval "OPENC3::MYDan::MonitorV3::NodeExporter::Collector::${type}::co( \$input )";
                            warn "ERR: $@" if $@;
                            map{ $this{prom}->set($_->{name}, $_->{value}, $_->{lable}) if $declare{$_->{name}}; }@data;
                        }
                    );
                }
            ); 

        }
        else
        {
            $this{timer}{$type} = AnyEvent->timer(
                after => $i, 
                interval => 15,
                cb => sub {
                    my @data = eval "OPENC3::MYDan::MonitorV3::NodeExporter::Collector::${type}::co()";
                    warn "ERR: $@" if $@;
                    map{ $this{prom}->set($_->{name}, $_->{value}, $_->{lable}) if $declare{$_->{name}}; }@data;
                }
            ); 
        }
    }

    map{ $this{prom}->declare( $_, help => $declare{$_}, type => 'gauge' ); }keys %declare;

    #强制定义，避免模块异常，漏掉 
    map{ $this{prom}->set( 'node_collector_error', -1, +{ collector => $_ } ); }
        qw( node_carry node_disk_blocks node_disk_inodes node_exporter_prome node_http node_port_tcp node_port_udp node_sar node_system_uptime );

    bless \%this, ref $class || $class;
}

sub refresh
{
    my $this = shift;
    $this->{prom}->set( 'node_system_time', time );
    return $this;
}

sub format
{
    my $this = shift;
    my $ext = $promNodeExporterMetrics ? "\n# HELP Prometheus Node Exporter\n$promNodeExporterMetrics" : '';
    return $this->{prom}->format . $ext;
}

sub set
{
    my ( $this, @v )= @_;
    $this->{prom}->set( @v );
    return $this;
}

1;
