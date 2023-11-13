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
    return if $podid !~ /master/;

    my $current = `./getPodLogsCurrentValue.pl '$jobid' '$podid' 2000 10`;
    chomp $current;
    warn "current: $current\n";

    return unless $current;

    my $threshold = `./getPodLogsThreshold.pl '$jobid' '$podid' 10000 30`;
    chomp $threshold;
    warn "threshold: $threshold\n";
    return unless $threshold;

    $threshold *= 0.80;
    warn "threshold: $threshold\n";

    return if $current > $threshold;

    print '-' x 40, "\n";
    print "alarm: jobid=$jobid podid=$podid threshold=$threshold current=$current\n";

    print "\nJob Info:\n";
    system "./getJobInfo.sh '$jobid'";

    print "\nLog:\n";
    system "./getPodLogs.pl '$jobid' '$podid' 300|grep throughput|tail -n 10";
    print "\n" x 3;

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
