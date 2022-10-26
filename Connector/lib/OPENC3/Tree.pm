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

1;
