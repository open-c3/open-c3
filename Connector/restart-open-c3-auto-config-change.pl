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

my $first = "/var/open-c3.first.mark";
if( ! -f $first )
{
    sleep 5;

    system "$RealBin/restart-open-c3.sh restart";
    system "touch $first";
}

while(1)
{
    check();
    sleep 3;
}
