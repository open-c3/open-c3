package Code;

use warnings;
use strict;
use FindBin qw( $RealBin );

sub new
{
    my ( $class, $name ) = @_;

    die "name undef" unless $name;
    my $base = "$RealBin/..";

    my $private = -e "$base/private/code/$name" ? 'private/' : '';

    my $code = do "$base/${private}code/$name";

    die "load ${private}code: $name fail" unless $code && ref $code eq 'CODE';

    bless +{ code => $code }, ref $class || $class;
}

sub run
{
    my $code = shift->{code};
    &$code( @_ );
}

1;
