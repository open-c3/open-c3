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

die "rsync fail: $!" if system "rsync -av $MYDan::PATH/PKG/Connector-$o{version}/ $MYDan::PATH/Connector/ --exclude conf/ --delete";

die "SetENV fail: $!" if system "$MYDan::PATH/Connector/tools/SetEnv -e '$o{envname}'";
die "restart fail: $!" if system "$MYDan::PATH/Connector/tools/restart";
die "Check fail: $!"   if system "$MYDan::PATH/Connector/tools/Check";
