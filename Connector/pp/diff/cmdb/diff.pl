#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;

$|++;

=head1 SYNOPSIS

 $0 treeid

=cut

my $id = shift @ARGV;

die "nofind treeid" unless $id && $id =~ /^\d+$/;

my    @v1 = `c3mc-base-fullnodeinfo $id --col name,type,inip,exip`;
chomp @v1;

my    @v2 = `c3mc-base-fullnodeinfo $id --col name,type,inip,exip --skip_ingestion_api --force_ingestion_cmdb`;
chomp @v2;

my $len  = scalar @v1;

my %v1 = map{ $_ => 1 }@v1;
my %v2 = map{ $_ => 1 }@v2;

map{ delete $v2{$_} }@v1;
map{ delete $v1{$_} }@v2;

map{ print "$id add: $_\n"; }keys %v2;
map{ print "$id del: $_\n"; }keys %v1;

print "$id OK $len\n" if ( ! %v1 ) && ( ! %v2 );
