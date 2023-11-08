#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;

$|++;

=head1 SYNOPSIS

 $0

=cut


my @jobid = `./ListJobs.sh`;
chomp @jobid;

use Data::Dumper;
use JSON;


sub getpodlog
{
    my ( $jobid, $podid ) = @_;
    warn "jobid: $jobid podid: $podid\n";

    my @log = `./getPodLogs.py '$jobid' '$podid' 20000`;
    chomp @log;
    my $x = JSON::decode_json( join('', @log) );
    return unless $x->{Logs};

    map{ print "$jobid $podid $_\n" }@{$x->{Logs}};
}


sub runinjob
{
    my $jobid = shift @_;
#    print "jobid: $jobid\n";

    my @podid = `./getPodId.sh '$jobid'`;
    chomp @podid;

    map{ getpodlog( $jobid, $_ ) }@podid;
}

map{ runinjob($_) }@jobid;
