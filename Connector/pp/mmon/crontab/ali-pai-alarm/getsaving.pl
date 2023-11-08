#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;

use YAML::XS;

$|++;

=head1 SYNOPSIS

 $0

=cut

my $path = "/data/open-c3-data/ali-pai/saving";

system "mkdir -p '$path'" unless -d $path;


my @x = `ls /data/open-c3-data/ali-pai/saving|grep -v done`;
chomp @x;



my %res;
sub run
{
    my $uuid = shift @_;

    my $d = YAML::XS::LoadFile "$path/$uuid";

    push @{$res{$d->{jobid}}}, $d->{data};
    system "mv '$path/$uuid' '$path/$uuid.done'";
    
}

map{ run( $_ )}@x;


for my $jobid ( keys %res )
{
    print '-' x 40, "\n";
    print "saving: jobid=$jobid\n";


    print "\nJob Info:\n";
    system "./getJobInfo.sh '$jobid'";

    print "\nLog:\n";
    map{ print "$_\n" }@{$res{$jobid}};
    print "\n" x 3;
}
