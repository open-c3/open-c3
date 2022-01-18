package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::Dmesg;

use strict;
use warnings;
use Carp;
use POSIX;

use Data::Dumper;
use MYDan::Collector::Util;

our %declare = (
    node_dmesg => 'display message',
);

my %REGEX = 
(
    'I/O error' => 'IO',
    'SCSI error' => 'SCSI',
    'SCSI bus speed downshifted' => 'SCSI',
    'Fatal drive error' => 'DRIVE',
    'CHECK CONDITION sense key' => 'sense',
    '.*error.*returned' => 'returned',
    'mpt2.*log_info.*originator.*code.*sub_code' => 'mpt2',
    'task abort' => 'taskabort',
    'sd.*timing out command' => 'timing',
    'Hardware Error(?!]: Machine check events logged)' => 'Hardware',
    'pblaze_pcie_interrupt' => 'flash',
);

our $cmd;
BEGIN{
    my $grep = join '|', keys %REGEX;
    $cmd = "dmesg |grep -iE -m 10 \"$grep\"";
};

sub co
{
    my @data = split /\n/, shift;
    my %data = map{ $_ => 0 }values %REGEX;

    for my $data ( @data )
    {
        map { if( $data =~ /$_/ ) { $data{$REGEX{$_}} ++; next; } }keys %REGEX;
    }

    my ( $error, @res ) = ( 0 );

    for my $name ( keys %data )
    {
        push @res, +{ name => 'node_dmesg', value => $data{$name}, lable => +{ type => $name} };
    }

    push @res, +{ name => 'node_collector_error', value => $error, lable => +{ collector => 'node_dmesg' } };
    return @res;
}

1;
