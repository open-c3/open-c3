#!/data/Software/mydan/perl/bin/perl -I/data/Software/mydan/Connector/lib
use strict;
use warnings;

$|++;

use YAML::XS;
use Encode;

=head1 SYNOPSIS

 $0

=cut

my $i18n = eval{ YAML::XS::LoadFile "/data/Software/mydan/Connector/lib/api/i18n.yaml" };
die "load i18n.yaml fail: $@" if $@;

my    @x = `grep 'C3T\\.' /data/Software/mydan/c3-front/src/app -R`;
chomp @x;

for my $x ( @x )
{
    my @xx =  $x =~ /'C3T\.([^']+)'/;
    push @xx, $x =~ /"C3T\.([^"]+)"/;
    unless( @xx )
    {
        print "no match: $x\n";
        next;
    }
    for my $str ( @xx )
    {
        my $estr = Encode::decode( 'utf8', $str );
        next if $i18n->{$estr};
        print "nofind: $str => $x\n";
    }
}
