#!/data/mydan/perl/bin/perl
use strict;
use warnings;

=head1 SYNOPSIS

 $0

=cut

my ( $normal, $testonly, $docker ) = map{
    my $x = `c3mc-sys-ctl ci.dist.$_.count`;
    chomp $x;
    die "ci.dist error" unless defined $x && $x =~ /^\d+$/;
    $x
}qw( normal testonly docker );

print "normal: $normal testonly: $testonly docker: $docker\n";

my @flow = `c3mc-base-db-get -t openc3_ci_project id ci_type`;
chomp @flow;

if( @flow <= 10 )
{
    warn "maybe some error here, skip.\n";
    exit;
}

my %flowid = map{ split /;/, $_, 2 }@flow;

sub _clean_repo_testonly
{
    my $repo = shift @_;
    my @file = glob "$repo/*testonly*";
    my %file;
    map{ $file{$_} = ( stat $_ )[9] }@file;
    @file = grep{ -f }sort{ $file{$a} <=> $file{$b} }keys %file;
    while( @file > $testonly )
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

    my $keep =  $flowid{$id} ? $flowid{$id} eq 'kubernetes' ? $docker : $normal : 0;

    next unless @file >= $keep;
    my %mtime;
    map{ $mtime{$_ } = (stat $_ )[9] }@file;

    @file = sort{ $mtime{$a} <=> $mtime{$b} } @file; 

    splice @file, -$keep, $keep;
    unlink @file;
    map{ print "rm file: $_\n" }@file;
}
