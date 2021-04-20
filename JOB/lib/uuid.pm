package uuid;

use warnings;
use strict;

sub new
{
    my ( $class, %this ) = @_;

    $this{chars} ||= [ "A" .. "Z", "a" .. "z", 0 .. 9 ];
    $this{end} ||= [ "a" .. "z" ];
    $this{length} ||= 12;
    bless \%this, ref $class || $class;
}

sub create_str
{
    my $this = shift;

    my ( $chars, $end, $length ) = @$this{qw( chars end length )};
    join("", @$chars[ map { rand @$chars } ( 1 .. $length - 1 ) ]).$end->[rand @$end];
}

1;
