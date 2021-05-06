package keepalive;

use warnings;
use strict;

sub new
{
    my ( $class, $db ) = @_;
    my $x = $db->query( "select `slave`,`time` from openc3_jobx_keepalive" );
    die "get data error from db\n" unless defined $x && ref $x eq 'ARRAY';
    die "keepalive null" unless @$x;

    bless +{ map{ $_->[0] => $_->[1] }@$x }, ref $class || $class;
}

sub slave
{
    my $this = shift;

    my $time = time - 90;
    $time = time - 300 unless grep{ $_ ge $time } values %$this;

    map{ delete $this->{$_} if $this->{$_} lt $time  }keys %$this;

    return undef unless my @slave = keys %$this;
    return $slave[int rand scalar @slave];
}

1;
