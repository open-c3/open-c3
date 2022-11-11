#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;

sub _clean_repo
{
    my $repo = shift @_;
    my @file = glob "$repo/*testonly*";
    my %file;
    map{ $file{$_} = ( stat $_ )[9] }@file;
    @file = grep{ -f }sort{ $file{$a} <=> $file{$b} }keys %file;
    while( @file > 10 )
    {
        my $file = shift @file;
        unlink $file;
        print "rm file: $file\n";
    }
}

sub clean_repo
{
    my $dir = shift @_;
    for my $d ( glob "$dir/*" )
    {
        next unless -d $d;
        next unless $d =~ /\/\d+$/;
        _clean_repo( $d );
    }
}

map{ clean_repo( $_ ); }qw( /data/open-c3-data/glusterfs/ci_repo );
