package OPENC3::Oncall::Period;

use base qw( OPENC3::Oncall MYDan::Node::Integer );

use strict;
use warnings;

use Carp;

our $SEP = qr/[^:~\d\w]/;
our %RGX = %OPENC3::Oncall::RGX;

=head1 SYNOPSIS

 use OPENC3::Oncall::Period;
 
 my $period = OPENC3::Oncall::Period->new( '07:13 ~ 13:20, 23:00 ~ 02:23' );
 my ( $range, $event ) = $period->dump( $dt1, $dt2, period => 7 );

=cut
sub new
{
    my ( $class, $expr ) = splice @_;
    my $self = $class->SUPER::new();

    while ( $expr && $expr =~ s/^\s*($RGX{hour}):($RGX{minute})\s*
        ~\s*($RGX{hour}):($RGX{minute})$SEP*//gx )
    {
        my $day = OPENC3::Oncall::DAY * ( $1 > $3 || $1 == $3 && $2 > $4 );
        my $duration = $self->new()->load
        (
            $1 * OPENC3::Oncall::HOUR + $2 * OPENC3::Oncall::MINUTE,
            $3 * OPENC3::Oncall::HOUR + ( $4 + 1 ) * OPENC3::Oncall::MINUTE - 1 + $day
        );
        $self->add( $duration );
    }
    return length $expr ? croak "invalid expression -> $expr" : $self;
}

=head1 METHODS

=head3 dump( $begin, $end, %param )

Returns a range of durations and a list of events
indicated by seconds since epoch.

 period: interation
 day: days to select by

=cut
sub dump
{
    my ( $self, $begin, $end, %param ) = splice @_;
    my $period = $param{period} || 1;
    my %day = map { $_ % $period => 1 } @{ $param{day} || [ 1 .. $period ] };
    my ( @duration, %event ) = $self->list( skip => 1 );
    my $range = $self->SUPER::new();
    my ( $now, $then ) = map { $_->epoch } $begin, $end;

    for ( my $i = 1; $now < $then; $i ++ )
    {
        next unless $day{ $i % $period };

        my $dt = $begin->clone->add( days => $i - 1 );
        $event{ $now = $dt->epoch } = 1; ## rotation point
        my $today = $dt->set( map { $_ => 0 } qw( hour minute second ) )->epoch;

        for my $duration ( @duration )
        {
            my @duration = map { $_ + $today } @$duration;
            $range->add( $range->new()->load( @duration ) );
            $duration[1] ++; @event{@duration} = 1 .. 2;
        }
    }
    return $range, [ keys %event ];
}

1;
