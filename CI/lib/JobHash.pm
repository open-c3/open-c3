package JobHash;

use warnings;
use strict;
use Util;

sub new
{
    my ( $class, $db ) = @_;
    my $x = $db->query( "select `slave`,`time` from openc3_ci_keepalive" );
    die "get data error from db\n" unless defined $x && ref $x eq 'ARRAY';
    die "keepalive null" unless @$x;

    my @node = sort map{ $_->[0] }grep{ time - 120 < $_->[1] && $_->[1] < time + 120 }@$x;

    my $myname = `c3mc-base-hostname`;
    chomp $myname;

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
