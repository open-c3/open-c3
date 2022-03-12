package OPENC3::Oncall::Calendar;

use strict;
use warnings;

use Carp;

our ( @HEADER, @MONTH, $MONTH, $YEAR ) =
(
    'SUM  MON  TUE  WED  THU  FRI  SAT', qw( January February March April
    May June July August September October November December )
);

format MONTH =
@|||||||||||||||||||||||||||||||||||
$MONTH
@|||||||||||||||||||||||||||||||||||
$HEADER[0]
.

format QUARTER =

@|||||||||||||||||||||||||||||||||||@|||||||||||||||||||||||||||||||||||@|||||||||||||||||||||||||||||||||||
@MONTH 
@|||||||||||||||||||||||||||||||||||@|||||||||||||||||||||||||||||||||||@|||||||||||||||||||||||||||||||||||
@HEADER[0,0,0]
.

format YEAR =
@|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
$YEAR
.

=head1 SYNOPSIS

 use OPENC3::Oncall::Calendar;
 
 OPENC3::Oncall::Calendar->new( $year, %block )->print( $month );

=cut
sub new
{
    my ( $class, $year, %block ) = @_;
    confess 'year must be within 1753 .. 9999' if $year < 1753 || $year > 9999;

    while ( my ( $month, $block ) = each %block )
    {
        my $ref = $block ? ref $block : '';
        if ( $ref eq 'ARRAY' ) { $block{$month} = { map { $_ => 1 } @$block } }
        elsif ( $ref ne 'HASH' ) { delete $block{$month} };
    }
    bless [ $year => %block ], ref $class || $class;
}

sub print
{
    my ( $self, $month ) = splice @_;
    my ( $year, %select ) = @$self;

    return $self->month( $month ) if $month;
    $YEAR = $year; $~ = 'YEAR'; write;

    for my $q ( 1 .. 4 )
    {
        my %month = map { $_ => OPENC3::Oncall::Calendar::Month->new( $year, $_ ) }
        my @month = map { $_ + ( $q - 1 ) * 3 } 1 .. 3;

        @MONTH = @HEADER[@month]; $~ = 'QUARTER'; write;
        $self->dump( %month );
    }
    return $self;
}

sub month
{
    my ( $self, $index ) = splice @_;
    my ( $year, %block ) = @$self;

    $MONTH = sprintf '%s %s', $HEADER[$index], $year; $~ = 'MONTH'; write;
    $self->dump( $index => OPENC3::Oncall::Calendar::Month->new( $year, $index ) );
}

sub dump
{
    my ( $self, %month ) = splice @_;
    my ( $year, %block ) = @$self;
    my @month = sort { $a <=> $b } keys %month;

    for my $w ( 0 .. 5 )
    {
        for my $m ( @month )
        {
            if ( my $week = $month{$m}->week( $w ) )
            {
                my $block = $block{$m} || {};
                map { printf '%5s', $block->{$_} ? ( $block->{$_} eq 1 ? "{$_}" : (  $block->{$_} eq 2 ? "[$_]" : "($_)" ) ) : " $_ " } @$week;
                print ' ';
            }
            else
            {
                print ' ' x 22;
            }
        }
        print "\n";
    }
    return $self;
}

package OPENC3::Oncall::Calendar::Month;

use strict;
use warnings;

use POSIX;

sub new
{
    my ( $class, $year, $month ) = splice @_;
    my $dow = POSIX::strftime( '%w' , 0, 0, 0, 1, $month - 1, $year - 1900 );
    my $count = ( 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 )[$month];
    my ( @self, @sun ) = [ map { '' } 0 .. $dow - 1 ];

    push @{ $self[0] }, map { $_ - $dow + 1 } $dow .. 6;
    $count += $year % 100 && ! ( $year % 4 && $year % 400 ) if $month == 2;

    for ( my $i = ( $dow <= 0 ? 1 : 8 ) - $dow; $i <= $count; $i += 7 )
    {
        push @sun, $i;
    }
    unshift @sun, '' if $sun[0] != 1;
    
    for my $row ( 1 .. 5 )
    {
        my $i = $sun[$row];
        push @self, $i ? [ map { $i <= $count ? $i ++ : '' } 0 .. 6 ] : undef;
    }
    bless \@self, ref $class || $class;
}

sub week
{
    my $self = shift;
    return $self->[ shift ];
}

1;
