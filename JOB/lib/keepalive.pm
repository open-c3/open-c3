package keepalive;

use warnings;
use strict;

sub new
{
    my ( $class, $db ) = @_;
    my $x = $db->query( "select `slave`,`time` from openc3_job_keepalive" );
    die "get data error from db\n" unless defined $x && ref $x eq 'ARRAY';
    die "keepalive null" unless @$x;

    bless +{ map{ $_->[0] => $_->[1] }@$x }, ref $class || $class;
}

sub _slave
{
    my $this = shift;

    my $time = time - 90;
    $time = time - 300 unless grep{ $_ ge $time } values %$this;

    map{ delete $this->{$_} if $this->{$_} lt $time  }keys %$this;
    return keys %$this;
}

sub slave
{
    my $this = shift;
    my @slave = $this->_slave();
    return undef unless @slave;
    return $slave[int rand scalar @slave];
}

sub role
{
    my ( $this, $name )  = @_;
    return unless $name;
    my @slave = $this->_slave();

    my $i = 0;
    for( sort @slave  )
    {
        if( $_ eq $name )
        {
            print $i ? "slave\n" : "master\n";
        }
        $i ++;
    }
}

1;
