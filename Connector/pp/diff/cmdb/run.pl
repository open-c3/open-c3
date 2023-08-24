#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;

$|++;

=head1 SYNOPSIS

 $0

=cut

sub getid
{
    my $cmd = shift @_;
    my @x = `$cmd`;
    chomp @x;
    return @x;
}

my %x;
map{ $x{$_} ++ } getid("c3mc-base-db-get -t openc3_ci_project groupid  -f 'status=1'");
map{ $x{$_} ++ } getid("c3mc-base-db-get -t openc3_job_jobs projectid -f \"status='permanent'\"");

for my $id ( getid("c3mc-base-treemap  | awk -F';' '{print \$1}'") )
{
    next unless $x{$id};
    system "./diff.pl '$id'";
}
