package OPENC3::Tree;
use strict;
use warnings;

sub compress
{
    my %tree = map{ $_ => 1 }grep{ $_ }split /,/, join ',', @_;

    for my $name ( keys %tree )
    {
        my @name = split /\./, $name;
        $tree{$name} = @name if $tree{$name};
        pop @name;
        while( @name )
        {
            my $pname = join '.', @name;
            delete $tree{$pname};
            pop @name;
        }
    }

    return join ',', sort{ $tree{$a} <=> $tree{$b} }keys %tree;
}

sub merge
{
    my $tree = join ',', @_;
    my %tree = map{ $_ => 1 }grep{ $_ }split /,/, $tree;
    return $tree unless 1 < keys %tree;

    my %cnt;
    for my $name ( keys %tree )
    {
        my @name = split /\./, $name;
        pop @name;
        while( @name )
        {
            my $pname = join '.', @name;
            $cnt{ $pname } ++;
            pop @name;
        }
    }

    my $cnt = keys %tree;
    my ( $match ) = sort{ length($b) <=> length($a) } grep { $cnt{$_} eq $cnt } keys %cnt;

    return $tree unless $match;

    $match .= '.';

    my @subtree;
    my $mlen = length $match;

    for my $name ( keys %tree )
    {
        my $subname = substr $name, $mlen;
        push @subtree, $subname;
    }

    return sprintf "$match\{%s\}", join ',', sort @subtree;
}

1;
