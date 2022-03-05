package TreeMap;

use warnings;
use strict;

#map2tree tree2map mapgrep treegrep mapgrepeid

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

    for my $id ( sort{ $map{$a} cmp $map{$b} }@currid )
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

sub tree2map
{
    return _tree2map( shift @_ );
}

sub _tree2map
{
    my ( $tree, $len, $head ) = @_;
    $len ||= 1;
    $head ||= '';

    my @map;
    for my $t ( @$tree )
    {
        push @map, +{ len => $len, id => $t->{id}, name => "$head$t->{name}", update_time => '0000-00-00 00:00:00' };
        next unless $t->{children};

        my $m = _tree2map( $t->{children}, $len + 1, "$head$t->{name}." );
        push @map, @$m;
    }
    return \@map;
}

sub mapgrep
{
    my ( $map, @id ) = @_;
    return tree2map( treegrep( map2tree( $map ), @id ) );
}

sub mapgrepeid
{
    my ( $map, $eid ) = @_;
    return [ grep{ $eid->[0] <= $_->{id} && $_->{id} <= $eid->[1] }@$map ];
}

sub treegrep
{
    my ( $tree, @id ) = @_;
    my @res;
    map
    {
        my $t = _gettreebyid( $_, $tree );
        push @res, @$t;
     
    }@id;
    return \@res;
}

sub _gettreebyid
{
    my ( $id, $data ) = @_;
    my $res = [];
    for my $d ( @$data )
    {
        if( $d->{id} eq $id )
        {
            return [ $d ];
        }
        else
        {
            if( $d->{children} && ref $d->{children} eq 'ARRAY' )
            {
                my $x = _gettreebyid( $id, $d->{children} );
                $res = $x if $x && ref $x eq 'ARRAY' && @$x > 0;
            }
        }
    }
    return $res;
};

1;
