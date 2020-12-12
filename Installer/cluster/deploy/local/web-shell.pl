#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;

use MYDan;
use MYDan::Util::OptConf;

$| ++;

=head1 SYNOPSIS

 $0 --envname txy --version 001

=cut

my $option = MYDan::Util::OptConf->load();
my %o = $option->get( qw( envname=s version=s ) )->dump();
$option->assert( qw( envname  version  ) );

die "rsync fail: $!" if system "rsync -av $MYDan::PATH/PKG/web-shell-$o{version}/ $MYDan::PATH/web-shell/ --delete";
die "restart fail: $!" if system "$MYDan::PATH/web-shell/tools/cluster/restart";
