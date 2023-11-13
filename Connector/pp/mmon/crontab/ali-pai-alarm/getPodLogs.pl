#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;

$|++;

=head1 SYNOPSIS

 $0

=cut


use JSON;

my ( $jobid, $podid, $len ) = @ARGV;

$len = 2000 unless $len;

my @log = `./getPodLogs.py '$jobid' '$podid' $len`;
chomp @log;
my $x = JSON::decode_json( join('', @log) );
exit unless $x->{Logs};

map{ print "$_\n" }@{$x->{Logs}};
