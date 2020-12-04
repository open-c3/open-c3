package Format;
use warnings;
use strict;

sub new
{
    my ( $class, @format ) = @_;

    bless +{ format => \@format }, ref $class || $class;
}

sub check
{
    my ( $this, %data ) = @_;
    while( @{$this->{format}} )
    {
        my ( $k, $v, $s ) = splice @{$this->{format}}, 0, 3;
        next if !$s && ! defined $data{$k};
        return "$k undef" unless defined $data{$k};
        if(ref $v eq 'ARRAY' )
        {
            my ( $g, @d ) = @$v;
            if( $g eq 'match' )
            {
                return "$k format error $d[0]" unless $data{$k} =~ $d[0];
            }
            elsif( $g eq 'mismatch' )
            {
                return "$k format error" unless $data{$k} !~ $d[0];
            }
            elsif( $g eq 'in' )
            {
                return sprintf( "$k need in %s", join ',',@d )  unless grep{ $_ eq $data{$k} }@d;
            }
            elsif( $g eq 'notin' )
            {
                return sprintf( "$k not allow in %s", join ',',@d ) if grep{ $_ eq $data{$k} }@d;
            }
            else
            {
                return "$k opetation unkown";
            }
        }
        else
        {
            return "$k format error $v" unless $data{$k} =~ $v;
        }
    }
    return undef;
}

1;
