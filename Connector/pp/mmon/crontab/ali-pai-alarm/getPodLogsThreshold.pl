#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;

$|++;

=head1 SYNOPSIS

 $0

=cut


use JSON;

my ( $jobid, $podid, $len, $cnt ) = @ARGV;


my $tmp = "/tmp/ali-pai.$jobid.$podid";

if ( -f $tmp )
{
    my $x = `cat '$tmp'`;
    print $x;
    exit;
}

my @log = `./getPodLogs.pl '$jobid' '$podid' $len`;
chomp @log;

my @x;

for(@log)
{
    if( $_ =~ /throughput: ([\d+\.]+) samples\/sec/ )
    {
        push @x, $1;
        last if @x >= $cnt;
    }
}

if( @x == $cnt )
{
    my $sum = 0; map{ $sum += $_ }@x;
    my $res = sprintf "%0.2f", $sum / $cnt;
    system "echo '$res' > '$tmp'";
    print "$res\n";
}
