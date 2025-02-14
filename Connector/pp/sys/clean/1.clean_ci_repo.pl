#!/data/mydan/perl/bin/perl
use strict;
use warnings;

=head1 SYNOPSIS

 $0

=cut

my @flowid = `c3mc-base-db-get -t openc3_ci_project id`;
chomp @flowid;

die "maybe some error here, skip." if @flowid <= 10;

my %flowid = map{ $_ => 1 }@flowid;

sub _clean_repo_testonly
{
    my $repo = shift @_;
    my @file = glob "$repo/*testonly*";
    my %file;
    map{ $file{$_} = ( stat $_ )[9] }@file;
    @file = grep{ -f }sort{ $file{$a} <=> $file{$b} }keys %file;
    while( @file > 5 )
    {
        my $file = shift @file;
        unlink $file;
        print "rm file: $file\n";
    }
}

for my $dir ( glob "/data/open-c3-data/glusterfs/ci_repo/*" )
{
    next unless $dir =~ /\/(\d+)$/;
    my $id = $1;

    _clean_repo_testonly( $dir );

    my @file;
    for my $file ( glob "$dir/*" )
    {
        push @file, $file;
    }

    my $keep = 10;
    $keep = 0 unless $flowid{$id};

    next unless @file >= $keep;
    my %mtime;
    map{ $mtime{$_ } = (stat $_ )[9] }@file;

    @file = sort{ $mtime{$a} <=> $mtime{$b} } @file; 

    splice @file, -$keep, $keep;
    unlink @file;
}
