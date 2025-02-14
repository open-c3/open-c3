#!/data/mydan/perl/bin/perl
use strict;
use warnings;

=head1 SYNOPSIS

 $0

=cut

my @treeid = `c3mc-base-treemap | awk -F ';' '{print \$1}'`;
chomp @treeid;

my %treeid  = map{ $_ => 1}@treeid;

my @flow = `c3mc-base-db-get id groupid -t openc3_ci_project`;
chomp @flow;

my %id;

for ( @flow )
{
    my ( $id, $treeid ) = split /;/, $_;
    next unless $treeid{$treeid};
    $id{$id} ++;
}

my @x = `docker ps -a --filter "name=^ci_build_id" --filter "status=exited" --format "{{.ID}} {{.Names}}"`;
chomp @x;

for( @x )
{
    my ( $cid, $cname ) = split / /, $_;
    next unless $cname =~ /ci_build_id_(\d+)_id/;
    my $tid = $1;
    if( $id{$tid} )
    {
        print "skip $cname\n";
    }
    else
    {
        print "delete $cname\n";
        system "docker rm '$cid'";
    }
}
