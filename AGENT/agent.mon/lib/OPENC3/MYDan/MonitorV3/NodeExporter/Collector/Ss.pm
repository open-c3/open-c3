package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::Ss;

use strict;
use warnings;
use Carp;
use POSIX;

our %declare = (
    node_ss_orphaned          => 'orphaned metric for ss command from Linux',
    node_ss_closed            => 'closed metric for ss command from Linux',
    node_ss_timewait          => 'timewait metric for ss command from Linux',
    node_ss_slabinfo_timewait => 'slabinfo_timewait metric for ss command from Linux',
    node_ss_synrecv           => 'synrecv metric for ss command from Linux',
    node_ss_estab             => 'estab metric for ss command from Linux',
);

our $collectorname = 'node_ss';
our $cmd = 'LANG=en ss -s';

#Total: 2101 (kernel 2469)
#TCP:   440 (estab 16, closed 394, orphaned 0, synrecv 0, timewait 16/0), ports 0
#
#Transport Total     IP        IPv6
#*	  2469      -         -        
#RAW	  1         0         1        
#UDP	  11        9         2        
#TCP	  46        41        5        
#INET	  58        50        8        
#FRAG	  0         0         0 
sub co
{
    my @ss = split /\n/, shift;
    my ( $error, @stat ) = ( 0 );
    eval{
        my $cont;
        for my $x ( @ss )
        {
            if( $x =~ /^TCP:.+\((.+)\)/ )
            {
                $cont = $1;
                last;
            }
        }
        die "No valid information found" unless $cont;
        my $lable = +{};

        for my $xx ( qw( estab closed orphaned synrecv ) )
        {
            push @stat, +{ name => "node_ss_$xx", value => $1, lable => $lable } if $cont =~ /$xx\s+(\d+)/;
        }
        if( $cont =~ /timewait\s+(\d+)\/(\d+)/ )
        {
            my ( $timewait, $slabinfo_timewait ) = ( $1, $2 );
            push @stat, +{ name => "node_ss_timewait",         value => $timewait,           lable => $lable };
            push @stat, +{ name => "node_ss_slabinfo_timewait", value => $slabinfo_timewait, lable => $lable };
        }
    };
    if( $@ )
    {
        warn "collector node_ss_* err:$@";
        $error = 1;
    }

    $error = 1 if @stat ne 6;

    push @stat, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };
    return @stat;
}

1;
