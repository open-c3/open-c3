package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::Coredump;

use strict;
use warnings;
use Carp;
use POSIX;
use File::Basename;

our %declare = (
    node_coredump => 'linux coredump'
);

our $collectorname = '';
our $cmd = 'sysctl -n kernel.core_pattern';

sub co
{
    my ( $path, @stat ) = shift;
    return () unless $path;
    chomp $path;
    my $dir = File::Basename::dirname( $path );

    return () if $path =~ / / || ! -e $dir;

    $path =~ s/%\w/*/g;

    my %core = ( any => +{ '1m' => 0, '5m' => 0, '15m' => 0, 'all' => 0 } );

    my $ct = time;
    for my $file ( grep{ -f $_ } glob $path )
    {
        my $time = ( stat $file )[9];

        if( $file =~ /\.core$/ )
        {
            if( $ct - $time > 432000 ) { unlink $file; next; }
            chmod 0644, $file;
        }

        my $name = File::Basename::basename( $file );
        $name =~ s/\d+/0/g;

        $core{$name}{all} ++; $core{'any'}{all} ++;
        if( $ct - $time < 60  ){$core{$name}{'1m'}++;  $core{'any'}{'1m'}++;};
        if( $ct - $time < 300 ){$core{$name}{'5m'}++;  $core{'any'}{'5m'}++;};
        if( $ct - $time < 900 ){$core{$name}{'15m'}++; $core{'any'}{'15m'}++;};
    }

    for my $name ( sort keys %core )
    {
        push @stat, map{ +{ name => 'node_coredump', value => $core{$name}{$_} || 0, lable => +{ name => $name, time => $_ } } }qw( 1m 5m 15m all );
    }

    return @stat;
}

1;
