package keepalive;

use warnings;
use strict;

sub new
{
    my ( $class, $db ) = @_;
    my $x = $db->query( "select `slave`,`time` from openc3_agent_keepalive" );
    die "get data error from db\n" unless defined $x && ref $x eq 'ARRAY';
    die "keepalive null" unless @$x;

    bless +{ map{ $_->[0] => $_->[1] }@$x }, ref $class || $class;
}

sub slave
{
    my $this = shift;

    my @slave = grep{ time - 120 < $this->{$_} && $this->{$_} < time + 120  }keys %$this;
    return undef unless @slave;

    return $slave[int rand scalar @slave];
}

1;
