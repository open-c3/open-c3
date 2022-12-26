package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::Process;

use strict;
use warnings;
use Carp;
use POSIX;
use OPENC3::MYDan::MonitorV3::NodeExporter::Collector;

our %declare = (
    node_process_count => 'process count.',
    node_process_etime => 'process elapsed time.',
);

our $psdumpidx = 0;
our $collectorname = 'node_process';
our $cmd = 'LANG=en ps -eo ppid,pid,stat,etime,comm,cmd';

sub getProcessTime
{
    my ( $time, $day ) = reverse split /-/, shift;
    my $t = $day ? $day * 86400 : 0;
    my ( $s, $m, $h ) = reverse split /:/, $time;
    {
        $t += $s if $s;
        $t += ( $m * 60 ) if $m;
        $t += ( $h * 3600 ) if $h;
    }
    return $t;
}

sub co
{
    my @ps = split /\n/, shift;

    my $extprocess = $OPENC3::MYDan::MonitorV3::NodeExporter::Collector::extendedMonitor->{process};
    return ( +{ name => 'node_collector_error', value => 0, lable => +{ collector => $collectorname } } ) unless $extprocess;

    my ( $error, @stat, %check, %count ) = ( 0 );

    for my $type ( qw( name cmdline ) )
    {
        next unless $extprocess->{$type} && ref $extprocess->{$type} eq 'ARRAY';
        my @c;
        for my $c ( @{$extprocess->{$type}} )
        {
            if( $c =~ /^[a-zA-Z0-9 \.\-_@]+$/ || $c =~ /^[a-zA-Z0-9 \.\-_@]+;[a-zA-Z0-9][a-zA-Z0-9\.\-_]+$/ )
            {
                push @c, $c;
            }
            else
            {
                warn "monitor process $c skip";
                $error = 1;
            }
        }

        $check{$type} = \@c if @c;
    }

    eval{
        my $title = shift @ps;
        die "$cmd format unkown" unless $title =~ /^\s*PPID\s+PID\s+STAT\s+ELAPSED\s+COMMAND\s+CMD\s*$/;
        my $psdump;
        for ( @ps )
        {
            s/^\s*//g;
            my ( undef, $pid, $stat, $etime, $name, $cmd ) = split /\s+/, $_, 6;
            next if $stat =~ /^Z/;

            unless( $pid =~ /^\d+$/ ) { warn; $error = 1; next; }

            for my $type ( keys %check )
            {
                next unless $check{$type};

                my $data = $type eq 'name' ? $name : $cmd;
                for my $check ( @{$check{$type}} )
                {
                    my @check = split /;/, $check;
                    next if index( $data, $check[0] ) < 0;

                    $count{"$type:$check"} ++;
                    my $value = getProcessTime( $etime );
                    $psdump = 1 if $value <= 60;
                    push @stat, +{ name => 'node_process_etime', value => $value, lable => +{ $type => $check[0], app => $check[-1], pid => $pid } };
                }
            }
        }
        if( $psdump )
        {
            $psdumpidx ++;
            $psdumpidx = 0 if $psdumpidx > 240;
            eval{ YAML::XS::DumpFile "/opt/mydan/var/logs/monitor/openc3.mointor.process.debug.$psdumpidx", \@ps };
        }
    };
    if( $@ )
    {
        warn "collector node_process_* err:$@";
        $error = 1;
    }


    for my $type ( keys %check )
    {
        map{
            my @check = split /;/, $_;
            push @stat, +{ name => 'node_process_count', value => $count{"$type:$_"} || 0 , lable => +{ $type => $check[0], app => $check[-1] } };
        }@{$check{$type}};
    }

    push @stat, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };

    return @stat;
}

1;
