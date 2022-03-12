package OPENC3::Oncall::Policy;

use strict;
use warnings;

use Carp;
use DateTime;
use YAML::XS;
$YAML::XS::LoadBlessed = 1;

use OPENC3::Oncall::Period;

use constant { DURATION => '00:00 ~ 23:59', PERIOD => 1, NULL => '' };

=head1 SYNOPSIS

 use OPENC3::Oncall::Policy;

 OPENC3::Oncall::Policy->new( $conf )->dump( $cache );

 my $policy = OPENC3::Oncall::Policy->load( $cache );
 my $now = time;
 my $level = 2;

 $policy->set( $now - 86400, $now + 86400 );

 my $who = $policy->get( $now, $level );
 my %list = $policy->list( $level );

=head1 CONFIGURATION

A YAML file that contains a stream of site definitions,
each a HASH with the following keys:

I<required>:

 pivot: a date expression, for rotation
 queue: a list of items to rotate through

I<optional>:

 site: default '', name of site
 period: default 1
 timezone: default 'local'
 duration: default '00:00 ~ 23:59'
 day: days of coverage, default all
 level: levels of coverage, default all
 reverse: default 0, reverse escalation order if 1
 expire: a date expression, for expire

Coverage is processed in sequential order until met or defaulted to the
I<last> site ( or in reverse order, and default to the I<first> site if
'reverse' is set )

Hence I<duration>, I<level>, and I<day> do not apply to the default site.

I<example>:

 ---
 site: cn
 pivot: 2017.06.10
 queue:
 - user1
 - user2
 - user3
 ---
 site: us
 pivot: 2017.06.11 20:00
 expire: 2017.09.11 20:00
 timezone: America/Los_Angeles
 duration: '19:10 ~ 7:20'
 period: 7
 level: [ 1, 2 ]
 day: [ 1, 2, 3, 4, 5 ]
 queue:
 - usr1
 - usr2
 - usr3

=cut
sub new
{
    my $self = shift;
    $self->load( @_ );
}

=head1 METHODS

=head3 load( $path )

Loads object from $path

=cut
sub load
{
    my ( $class, $conf, %param ) = splice @_;
    croak "empty config" unless my @conf = YAML::XS::LoadFile $conf;

    @conf = reverse @conf if $param{reverse} || 0;
    $conf = $conf[-1];
    return $conf if ref $conf eq ( $class = ref $class || $class );
    delete @$conf{ qw( duration level day ) };

    for my $conf ( @conf )
    {
        my $error = 'invalid definition' . YAML::XS::Dump $conf;
        croak $error unless $conf && ref $conf eq 'HASH';

        map { $conf->{$_} || croak "$error: $_ not defined" } qw( queue pivot );
        $conf->{time_zone} = delete $conf->{timezone} || 'local';

        croak "$error: queue: not ARRAY" if ref $conf->{queue} ne 'ARRAY';
        croak "$error: invalid pivot" unless $conf->{pivot} = 
            OPENC3::Oncall->epoch( @$conf{ qw( pivot time_zone ) } );

        for my $key ( qw( level day ) )
        {
            my $val = delete $conf->{$key} || [];
            my $ref = ref $val;

            $val = $ref ? [] : [ split /\D+/, $val ] if $ref ne 'ARRAY';
            $conf->{$key} = $val if @$val;
        }

        $conf->{site} ||= NULL;
        $conf->{level} = { map { $_ => 1 } @{ $conf->{level} || [] } };
        $conf->{cycle} = ( $conf->{period} ||= PERIOD ) * @{ $conf->{queue} };
        $conf->{duration} = OPENC3::Oncall::Period->new( $conf->{duration} || DURATION );

        $conf->{expire} = $conf->{expire} ? OPENC3::Oncall->epoch( @$conf{ qw( expire time_zone ) } ) : 0;
    }
    bless \@conf, $class;
}

=head3 dump( $path )

Dumps object to $path

=cut
sub dump
{
    my ( $self, $path ) =  splice @_;
    YAML::XS::DumpFile $path, $self if $path;
    return $self;
}

=head3 set( $begin, $end )

Sets the scope

=cut
sub set
{
    my $self = shift;
    my ( $begin, $end ) = map { ! ref $_ ? DateTime->from_epoch( epoch => $_ )
        : $_->isa( 'DateTime' ) ? $_ : croak 'invalid time input' } @_;

    for my $conf ( @$self )
    {
        my $cycle = $conf->{cycle};
        my $pivot = DateTime->from_epoch
            ( epoch => $conf->{pivot}, time_zone => $conf->{time_zone} );

        $pivot->add( days => int( ( $begin->epoch - $pivot->epoch )
            / ( OPENC3::Oncall::DAY * $cycle ) ) * $cycle );

        $pivot->subtract( days => $cycle ) while $begin->epoch < $pivot->epoch;

        @$conf{ qw( range event ) } =
            $conf->{duration}->dump( $pivot, $end, %$conf );

        $conf->{range}->intersect
            ( $conf->{range}->new->load( $begin->epoch, $end->epoch ) );
    }
    return $self;
}

=head3 get( $time, $level )

Returns the event at $time for $level

=cut
sub get
{
    my ( $self, $time, $level ) = splice @_;

    for my $conf ( @$self )
    {
        my ( $range, $queue ) = @$conf{ qw( range queue ) };

        last unless $range;
        next if %{ $conf->{level} } && ! $conf->{level}{$level}
            || ! defined $range->index( $time );

        next unless $time > $conf->{pivot};
        next if $conf->{expire} && $time > $conf->{expire};

        my $i = int( ( $time - $conf->{pivot} )
            / ( OPENC3::Oncall::DAY * $conf->{period} ) );

        if ( $conf->{reverse} ) { $i += ( $level - 1 )} else { $i -= ( $level - 1 ) }
        $i += @$queue while $i < 0;

        return { site => $conf->{site}, item => $queue->[ $i % @$queue ] };
    }
    return undef;
}

=head3 list( $level )

Returns a HASH of events indexed by time for $level

=cut
sub list
{
    my ( $self, $level ) = splice @_;
    my $prev = { item => NULL };
    my %list = map { $_ => 1 } map { @{ $_->{event} } } @$self;

    for my $time ( sort { $a <=> $b } keys %list )
    {
        my $conf = $self->get( $time, $level );
        if ( ! $conf || $conf->{item} eq $prev->{item} )
        { delete $list{$time} } else { $prev = $list{$time} = $conf }
    }
    return wantarray ? %list : \%list;
}

1;
