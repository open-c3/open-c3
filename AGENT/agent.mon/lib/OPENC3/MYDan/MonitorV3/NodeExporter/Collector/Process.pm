package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::Process;

use strict;
use warnings;
use Carp;
use POSIX;
use OPENC3::MYDan::MonitorV3::NodeExporter::Collector;

our %declare = (
    node_process_count => 'process count.',
    node_process_time => 'process start time.',
);

our $collectorname = 'node_process';
our $cmd = 'LANG=en ps -eo pid,stat,etime,comm,cmd';

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
        $check{$type} = $extprocess->{$type};
    }

    eval{
        my $title = shift @ps;
        die "$cmd format unkown" unless $title =~ /^\s*PID\s+STAT\s+ELAPSED\s+COMMAND\s+CMD\s*$/;
        for ( @ps )
        {
            s/^\s*//g;
            my ( $pid, $stat, $etime, $name, $cmd ) = split /\s+/, $_, 5;
            next if $stat =~ /^Z/;

            unless( $pid =~ /^\d+$/ ) { warn; $error = 1; next; }

            for my $type ( keys %check )
            {
                next unless $check{$type};

                my $data = $type eq 'name' ? $name : $cmd;
                for my $check ( @{$check{$type}} )
                {
                    next if index( $data, $check ) < 0;

                    $count{"$type:$check"} ++;
                    push @stat, +{ name => 'node_process_time', value => getProcessTime( $etime ), lable => +{ $type => $check, pid => $pid } };
                }
            }
        }
    };
    if( $@ )
    {
        warn "collector node_process_* err:$@";
        $error = 1;
    }


    for my $type ( keys %check )
    {
        map{ push @stat, +{ name => 'node_process_count', value => $count{"$type:$_"} || 0 , lable => +{ $type => $_ } }; }@{$check{$type}};
    }

    push @stat, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };

    return @stat;
}

1;
