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

our $collectorname = '';

sub co
{
    my $extprocess = $OPENC3::MYDan::MonitorV3::NodeExporter::extendedMonitor->{process};

    return () unless $extprocess;

    my ( @proc, @stat );
    for ( glob "/proc/*" )
    {
        next unless $_ =~ m/^\/proc\/(\d+)$/;
        push @proc, $1;
    }

    if( $extprocess->{name} && ref $extprocess->{name} eq 'ARRAY' )
    {
        my @name = @{$extprocess->{name}};
        my %name = map{ $_ => 0 }@name;
        my %time = map{ $_ => 0 }@name;

        for my $pid ( @proc )
        {
            next unless tie my @temp, 'Tie::File', "/proc/$pid/status", mode => O_RDONLY, recsep => "\n";
            next unless @temp && $temp[0] =~ /^Name:\s*(.+)$/;
            my $temp = $1;
            map{
                my $t = $_;
                if( $t eq $temp )
                {
                    $name{$t} ++;
                    my $proctime = (stat "/proc/$pid")[10];
                    if( $proctime )
                    {
                       my $startTime = time - $proctime;
                       $time{$t} = $startTime if $startTime < $time{$t} || !$time{$t};
                    }

                }

            }@name;
        }
        for my $name ( keys %name )
        {
            push @stat, +{
                name => 'node_process_count',
                value => $name{$name},
                lable => +{ name => $name },
            };
        }
        for my $time ( keys %time )
        {
            push @stat, +{
                name => 'node_process_time',
                value => $time{$time},
                lable => +{ name => $time },
            };
        }

    }

    if( $extprocess->{cmdline} && ref $extprocess->{cmdline} eq 'ARRAY' )
    {
        my @cmdline = @{$extprocess->{cmdline}};
        my %cmdline = map{ $_ => 0 }@cmdline;
        my %time = map{ $_ => 0 }@cmdline;

        for my $pid ( @proc )
        {
            next unless tie my @temp, 'Tie::File', "/proc/$pid/cmdline", mode => O_RDONLY, recsep => "\n";
            next unless @temp;
            my $temp = $temp[0];
            map{
                my $t = $_;
                if( $temp =~ /$t/ )
                {
                    $cmdline{$t} ++;
                    my $proctime = (stat "/proc/$pid")[10];
                    if( $proctime )
                    {
                       my $startTime = time - $proctime;
                       $time{$t} = $startTime if $startTime < $time{$t} || !$time{$t};
                    }

                }
            }@cmdline;
        }
        for my $cmdline ( keys %cmdline )
        {
            push @stat, +{
                name => 'node_process_count',
                value => $cmdline{$cmdline},
                lable => +{ cmdline => $cmdline },
            };
        }
        for my $time ( keys %time )
        {
            push @stat, +{
                name => 'node_process_time',
                value => $time{$time},
                lable => +{ cmdline => $time },
            };
        }
    }

    if( $extprocess->{exe} && ref $extprocess->{exe} eq 'ARRAY' )
    {
        my @exe = @{$extprocess->{exe}};
        my %exe = map{ $_ => 0 }@exe;
        my %time = map{ $_ => 0 }@exe;

        for my $pid ( @proc )
        {
            next unless my $link = readlink "/proc/$pid/exe";
            map{
                my $t = $_;
                if( $link =~ /$t/ )
                {
                    $exe{$t} ++;
                    my $proctime = (stat "/proc/$pid")[10];
                    if( $proctime )
                    {
                       my $startTime = time - $proctime;
                       $time{$t} = $startTime if $startTime < $time{$t} || !$time{$t};
                    }
                }
            }@exe;
        }
        for my $exe ( keys %exe )
        {
            push @stat, +{
                name => 'node_process_count',
                value => $exe{$exe},
                lable => +{ exe => $exe },
            };
        }
        for my $time ( keys %time )
        {
            push @stat, +{
                name => 'node_process_time',
                value => $time{$time},
                lable => +{ exe => $time },
            };
        }
    }

    return @stat;
}

1;
