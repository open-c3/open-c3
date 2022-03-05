package TreeMap;

use warnings;
use strict;

sub _formatusertree
{
    my %map = @_;
    return [] unless %map;
    my ( @res, @currid, %submap );
    for my $id ( keys %map )
    {
        my @names = split /\./, $map{$id};
        if( @names == 1 )
        {
            push @currid, $id;
        }
        else
        {
            my ( $head, @name ) = @names;
            $submap{$head}{$id} = join '.', @name;
        }
    }

    for my $id ( sort{ $map{$a} <=> $map{$b} }@currid )
    {
        my $name = $map{$id};
        if( $submap{$name} )
        {
            push @res, +{ id => $id, name => $name, children => _formatusertree( %{$submap{$name}}) };
        }
        else
        {
            push @res, +{ id => $id, name => $name };
        }
    }

    return \@res;
};

sub map2tree
{
    my $map = shift @_;
    my %map;
    map{ $map{$_->{id}} = $_->{name} }@$map;
    return _formatusertree( %map );

};

1;
