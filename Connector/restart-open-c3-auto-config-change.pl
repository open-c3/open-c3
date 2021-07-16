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
        system "$RealBin/restart-open-c3.sh";
    }
}

system "$RealBin/restart-open-c3.sh start";

while(1)
{
    check();
    sleep 3;
}
