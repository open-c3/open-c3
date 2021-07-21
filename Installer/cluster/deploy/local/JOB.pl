#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;

use MYDan;
use MYDan::Util::OptConf;
use FindBin qw( $RealBin );

$| ++;

=head1 SYNOPSIS

 $0 --evnname txy --version 001

=cut

my $option = MYDan::Util::OptConf->load();
my %o = $option->get( qw( envname=s version=s ) )->dump();
$option->assert( qw( envname version  ) );

die "rsync fail: $!" if system "rsync -av $MYDan::PATH/PKG/JOB-$o{version}/ $MYDan::PATH/JOB/ --exclude conf/ --delete";

if( $o{version} =~ /^S/ )
{
    die "reload fail: $!" if system "$MYDan::PATH/JOB/tools/reload";
}
else
{
    die "SetENV fail: $!"  if system "$MYDan::PATH/JOB/tools/SetEnv -e '$o{envname}'";
    die "restart fail: $!" if system "$MYDan::PATH/JOB/tools/restart";
    die "Check fail: $!"   if system "$MYDan::PATH/JOB/tools/Check";
}
