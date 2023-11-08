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


sub printinfo
{

    my ( $jobid, $podid, @log )  = @_;
    print '-' x 40, "\n";
    print "notify: jobid=$jobid podid=$podid\n";

    print "\nJob Info:\n";
    system "./getJobInfo.sh '$jobid'";

    print "\nLog:\n";



    map{ print "$_\n" }@log;

    print "\n" x 3;
}
sub getpodlog
{
    my ( $jobid, $podid ) = @_;
    warn "jobid: $jobid podid: $podid\n";


    my @log = `./getPodLogs.pl '$jobid' '$podid' 3000`;
    chomp @log;
    my ( $log1len, $log2len, @log1, @log2 ) = (2,2);
    for my $log ( @log )
    {
        if( $log =~ /throughput: ([\d+\.]+) samples\/sec/ )
        {
            pop( @log1 ) if @log1 >= $log1len;
            push @log1, $log;
        }

        if( $log =~ /learning rate:/ )
        {
            pop( @log2 ) if @log2 >= $log1len;
            push @log2, $log;
        }
 
    }

    printinfo( $jobid, $podid, @log1, @log2 ) if @log1 || @log2;


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
