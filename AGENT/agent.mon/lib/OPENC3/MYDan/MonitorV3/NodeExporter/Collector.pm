package OPENC3::MYDan::MonitorV3::NodeExporter::Collector;

use warnings;
use strict;
use Carp;
use YAML::XS;
use IPC::Open3;
use Symbol 'gensym';
use AnyEvent;
use MIME::Base64;

use OPENC3::MYDan::MonitorV3::Prometheus::Tiny;

my %declare = (
    node_collector_error => 'Number of errors encountered during node exporter collection',
);

my %proc;
our $prom;
our $promelocal;
our $promeerror = 0;

our $extendedMonitor = +{};

my %sw;
my %hiatus;

sub new
{
    my ( $class, %this ) = @_;

    my %h = ( 'sar' => [ 'Sar' ] , 'ss --help' => [ 'PortTcp', 'PortUdp' ] );
    for my $h ( keys %h )
    {
        next unless system "$h >/dev/null 2>&1";
        map{ $hiatus{$_} = 1 }@{$h{$h}}
    }

    $prom = $this{prom} = OPENC3::MYDan::MonitorV3::Prometheus::Tiny->new;
    my @task = qw( DiskBlocks DiskInodes Uptime PortTcp PortUdp Process Http Path PromeNodeExporter Sar );

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
 
        $sw{$type} = 1;

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

                    if( $hiatus{$type} )
                    {
                        $this{prom}->set( 'node_collector_error', 3, +{ collector => $collectorname } );
                        return;
                    }

                    unless( $sw{$type} )
                    {
                        $this{prom}->set( 'node_collector_error', -2, +{ collector => $collectorname } );
                        return;
                    }

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
        qw( node_carry node_disk_blocks node_disk_inodes node_exporter_prome node_http node_port_tcp node_port_udp node_sar node_system_uptime node_process );

    $this{timer}{refresh} = AnyEvent->timer(
        after => 1, 
        interval => 15,
        cb => sub { 
            $this{prom}->set( 'node_exporter_version', 10 );
            $this{prom}->set( 'node_collector_error', $promeerror, +{ collector => 'node_exporter_prome' } ) if defined $promeerror;
            $promeerror = undef;           
        }
    );

    bless \%this, ref $class || $class;
}

sub get
{
    my ( $this, $debug ) = @_;

    $this->{prom}->set( 'node_system_time', time );

    my $content = $this->{prom}->format . ( $promelocal ? "\n# HELP Prometheus Node Exporter\n$promelocal" : '' );

    my @debug;
    if( $debug )
    {
        @debug = map{"# $_"}split /\n/, YAML::XS::Dump $extendedMonitor;
        unshift @debug, "# DEBUG";
    }

    return join "\n",
        "# HELP OPEN-C3 Node Exporter debug[$debug]",
        @debug,
        $content;
}

sub set
{
    my ( $this, @v )= @_;
    $this->{prom}->set( @v );
    return $this;
}

sub setExt
{
    my ( $this, $carry )= @_;
    return unless $carry;

    my $exmonitor = eval{ YAML::XS::Load decode_base64( $carry ) };
    warn "node exporter carry data err: $@" if $@;

    my $error = 1;
    if( $exmonitor && ref $exmonitor eq 'HASH' )
    {
        $extendedMonitor = $exmonitor;
        $error = 0;

        $sw{Process} = $extendedMonitor->{process} ? 1 : 0;
        $sw{PortTcp} = ( $extendedMonitor->{port} && ref $extendedMonitor->{port} eq 'HASH' && $extendedMonitor->{port}{tcp} ) ? 1 : 0;
        $sw{PortUdp} = ( $extendedMonitor->{port} && ref $extendedMonitor->{port} eq 'HASH' && $extendedMonitor->{port}{udp} ) ? 1 : 0;
    }
    $this->{prom}->set( 'node_collector_error', $error, +{ collector => 'node_carry' } );
}
1;
