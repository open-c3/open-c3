#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;
use FindBin qw( $RealBin );
use YAML::XS;
use MYDan;

=head1 SYNOPSIS

 $0

=cut

my $base = $RealBin;
$base =~ s#/[^/]+$##;

print "start\n";

system "ln -fsn /data/open-c3-data/glusterfs /data/glusterfs" unless -e "/data/glusterfs";

sub check
{
    my $configtime = ( stat "$RealBin/config.ini/current" )[9];
    my $laststarttime = ( stat "/etc/connector.mark" )[9];

    if( $configtime && $laststarttime && $configtime > $laststarttime)
    {
        print "start\n";
        my $tail = `tail -n 1 $RealBin/config.ini/current`;
        my $reload = ( ( $tail =~ /^#/ && $tail =~ /reload/ ) || $tail !~ /^#/ ) ? 'reload' : '';
        system "$RealBin/restart-open-c3.sh $reload";
    }
}

system "$RealBin/restart-open-c3.sh start";

while(1)
{
    sleep 3;
    last if -f "/etc/ci.exip" && -f "/etc/job.exip";
    system "$RealBin/restart-open-c3.sh restart";
}

while(1)
{
    check();
    sleep 3;
}
