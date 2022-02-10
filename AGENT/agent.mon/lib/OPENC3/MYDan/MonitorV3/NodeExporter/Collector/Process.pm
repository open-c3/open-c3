package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::Process;

use strict;
use warnings;
use Carp;
use POSIX;
use OPENC3::MYDan::MonitorV3::NodeExporter;
use Fcntl 'O_RDONLY';
use Tie::File;

our %declare = (
    node_process_count => 'process count.',
    node_process_time => 'process start time.',
);

our $collectorname = 'node_process';

sub getProcessTime
{
    my $pid = shift;
    return unless my $proctime = (stat "/proc/$pid")[10];
    return time - $proctime;
}

sub co
{
    my $extprocess = $OPENC3::MYDan::MonitorV3::NodeExporter::extendedMonitor->{process};

    return ( +{ name => 'node_collector_error', value => 0, lable => +{ collector => $collectorname } } ) unless $extprocess;

    my ( $error, @proc, @stat ) = ( 0 );
    for ( glob "/proc/*" )
    {
        next unless $_ =~ m/^\/proc\/(\d+)$/;
        push @proc, $1;
    }

    my %getProcessInfo = (
        name => sub{
            my $pid = shift;
            return unless tie my @temp, 'Tie::File', "/proc/$pid/status", mode => O_RDONLY, recsep => "\n";
            return if grep{/^State:\s+Z/}@temp;
            return unless @temp && $temp[0] =~ /^Name:\s*(.+)$/;
            return $1;
        },
        cmdline => sub{
            my $pid = shift;
            return unless tie my @temp, 'Tie::File', "/proc/$pid/cmdline", mode => O_RDONLY, recsep => "\n";
            return unless @temp;
            return $temp[0];
        },
        exe => sub{
            my $pid = shift;
            return readlink "/proc/$pid/exe";
        }
    );


    for my $type ( qw( name cmdline exe ) )
    {
        next unless $extprocess->{$type} && ref $extprocess->{$type} eq 'ARRAY' ;

        my @check = @{$extprocess->{$type}};
        my %count = map{ $_ => 0 }@check;

        for my $pid ( @proc )
        {
            next unless my $temp = &{$getProcessInfo{$type}}( $pid );

            for my $check ( @check )
            {
                next unless $temp =~ /$check/;
                $count{$check} ++;

                my $t = getProcessTime( $pid );
                push @stat, +{ name => 'node_process_time', value => $t, lable => +{ $type => $check, pid => $pid } } if defined $t;
            }
        }

        map{ push @stat, +{ name => 'node_process_count', value => $count{$_}, lable => +{ $type => $_ } } }@check;

    }

    push @stat, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };

    return @stat;
}

1;
