package OPENC3::Oncall;

use strict;
use warnings;

use DateTime;

use constant { WEEK => 604800, DAY => 86400, HOUR => 3600, MINUTE => 60 };

our $LTZ = DateTime::TimeZone->new( name => 'local' );
our %RGX =
(
    year => qr/[2-9]\d{3}/,
    month => qr/1[0-2]|0?[1-9]/,
    day => qr/3[01]|[1-2]\d|0?[1-9]/,
    hour => qr/2[0-3]|[0-1]?\d/,
    minute => qr/[0-5]?\d/,
    second => qr/[0-5]?\d/,
);

=head1 METHODS

=head3 epoch( $date, $tz )

Returns seconds since epoch of expression $date with timezone $tz

=cut
sub epoch
{
    my ( $class, $date, $tz ) = splice @_;
    my ( @key, %time ) = qw( year month day hour minute second );

    return undef unless my @time = split /\D+/, $date || '';
    push @time, 0 while @time < @key;

    for my $i ( 0 .. $#key )
    {
        my $key = $key[$i];
        return undef if $time[$i] !~ qr/^($RGX{$key})$/;
        $time{$key} = $1;
    }
    return DateTime->new( %time, time_zone => $tz || $LTZ )->epoch;
}

1;
