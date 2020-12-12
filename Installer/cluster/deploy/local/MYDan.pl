#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;
use MYDan;
use MYDan::Util::OptConf;

$| ++;

=head1 SYNOPSIS

 $0 --evnname txy --version 001

=cut

my $option = MYDan::Util::OptConf->load();
my %o = $option->get( qw( envname=s version=s ) )->dump();
$option->assert( qw( envname version  ) );

die "rsync fail: $!" if system "rsync -av $MYDan::PATH/PKG/MYDan-$o{version}/ $MYDan::PATH/MYDan/ --delete";
