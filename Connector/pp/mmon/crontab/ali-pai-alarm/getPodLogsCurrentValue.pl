#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;

$|++;

=head1 SYNOPSIS

 $0

=cut


use JSON;
use YAML::XS;
use Digest::MD5;

my ( $jobid, $podid, $len, $cnt ) = @ARGV;

my $path = "/data/open-c3-data/ali-pai/saving";

system "mkdir -p '$path'" unless -d $path;

my @log = `./getPodLogs.pl '$jobid' '$podid' $len`;
chomp @log;

my @x;

for(@log)
{
    if( $_ =~ /throughput: ([\d+\.]+) samples\/sec/ )
    {
        shift(@x) if @x >= $cnt;
        push @x, $1;
    }

    if( $_ =~ /saving checkpoint at iteration/ )
    {
        my $data = +{ data => $_, jobid => $jobid, podid => $podid };
        my $md5 = Digest::MD5->new->add( YAML::XS::Dump $data )->hexdigest;
        my $tmp = "$path/saving.$md5";

        next if -f $tmp || -f "$tmp.done";

        eval{ YAML::XS::DumpFile $tmp, $data };
        warn "Dump saving checkpoint at iteration fail: $@" if $@;
    }
}

if( @x == $cnt )
{
    my $sum = 0; map{ $sum += $_ }@x;
    printf "%0.3f\n", $sum / $cnt;
}
