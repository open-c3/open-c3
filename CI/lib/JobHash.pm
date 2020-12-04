package JobHash;

use warnings;
use strict;
use Util;

sub new
{
    my ( $class, $db ) = @_;
    my $x = $db->query( "select `slave`,`time` from keepalive" );
    die "get data error from db\n" unless defined $x && ref $x eq 'ARRAY';
    die "keepalive null" unless @$x;

    my %data  = map{ $_->[0] => $_->[1] }@$x;

    my $time = time - 90;
    $time = time - 300 unless grep{ $_ ge $time } values %data;

    map{ delete $data{$_} if $data{$_} lt $time  }keys %data;

    my @node = sort keys %data;

    my $myname = Util::myname();

    my $i;
    for( 0 .. $#node )
    {
        next unless $node[$_] eq $myname;
        $i = $_;
        last;
    }

    bless +{ index => $i, count => scalar @node }, ref $class || $class;
}

sub hash
{
    my ( $this, $id ) = @_;
    my ( $index, $count ) = @$this{qw( index count)};
    return ( ( $id % $count ) == $index) ? 1 : 0;
}
1;
