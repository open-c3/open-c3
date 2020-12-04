package Crontab;
use warnings;
use strict;

our @range = ( [0, 59, 'minute'], [ 0, 23, 'hour'], [1, 31, 'day'], [1, 12, 'month'], [0, 7, 'week'] );

sub new
{
    my ( $class, $str ) = @_;
    die "no str" unless $str;
    bless +{ str => $str }, ref $class || $class;
}

sub format
{
    my $str = shift->{str};
    return 'format err' if $str !~ /^[\*\/,0-9-]+\s+[\*\/,0-9-]+\s+[\*\/,0-9-]+\s+[\*\/,0-9-]+\s+[\*\/,0-9-]+$/;
    my @str = split /\s+/, $str;
    for( 0 .. $#str )
    {
        eval{ _subformat( $str[$_], $range[$_] ); };
        return "format err: $range[$_][2]" if $@;
    }

    return;

}

sub _subformat
{
    my ( $str, $range ) = @_;

    $str =~ s/\/\d+$//;

    map{ _check( $_, $range )}split /,/, $str;
    
}

sub _check
{
    my ( $str, $range ) = @_;

    return if $str eq '*';
    if( $str =~ /^(\d+)$/ )
    {
        return if $range->[0] <= $1 && $1 <= $range->[1];
    }

    if( $str =~ /^(\d+)\-(\d+)$/ )
    {
        return if $range->[0] <= $1 && $1 < $2  && $2 <= $range->[1];       
    }

    die "err";
}
1;
