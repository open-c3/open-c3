package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::ProcListen;

use strict;
use warnings;
use Carp;
use POSIX;

our %declare = (
    node_proc_listen => 'Program listen',
);

our $collectorname = 'node_proc_listen';
our $cmd = 'LANG=en netstat -nlpt';

#LANG=en netstat -nlpt
#Active Internet connections (only servers)
#Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
#tcp        0      0 0.0.0.0:3306            0.0.0.0:*               LISTEN      9589/docker-proxy   
#tcp        0      0 0.0.0.0:7788            0.0.0.0:*               LISTEN      30118/docker-proxy  
#tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      1/systemd           
#tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      27184/docker-proxy 

sub co
{
    my @netstat = split /\n/, shift;
    my ( $error, @stat ) = ( 0 );
    eval{
        my ( undef, $title ) = splice @netstat, 0, 2;
        die "netstat format unknown" unless $title =~ /^Proto\s+Recv-Q\s+Send-Q\s+Local\s+Address\s+Foreign\s+Address\s+State\s+PID\/Program\s+name\s*$/;
        for ( @netstat )
        {
            my ( $type, undef,undef, $addr, undef, $state, $program ) = split /\s+/, $_;
            my $name = $program =~ /^\d+\/(.+)$/ ? $1 : $program;

            my $lable = +{ addr => $addr, name => $name };

            push @stat, +{
                name => 'node_proc_listen',
                value => 1,
                lable => $lable,
            };
        }
    };
    if( $@ )
    {
        warn "collector node_proc_listen_* err:$@";
        $error ++;
    }

    push @stat, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };
    return @stat;
}

1;
