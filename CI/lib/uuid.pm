package uuid;

use warnings;
use strict;

sub new
{
    my ( $class, %this ) = @_;

    $this{chars} ||= [ "A" .. "Z", "a" .. "z", 0 .. 9 ];
    $this{length} ||= 12;
    bless \%this, ref $class || $class;
}

sub create_str
{
    my $this = shift;

    my ( $chars, $length ) = @$this{qw( chars length )};
    join("", @$chars[ map { rand @$chars } ( 1 .. $length ) ]);

}

1;
