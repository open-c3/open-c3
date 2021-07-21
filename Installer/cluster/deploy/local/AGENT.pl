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
$option->assert( qw( envname version ) );

die "rsync fail: $!" if system "rsync -av $MYDan::PATH/PKG/AGENT-$o{version}/ $MYDan::PATH/AGENT/ --exclude conf/ --delete";

if( $o{version} =~ /^S/ )
{
    die "reload fail: $!" if system "$MYDan::PATH/AGENT/tools/reload";
}
else
{
    die "SetENV fail: $!"  if system "$MYDan::PATH/AGENT/tools/SetEnv -e '$o{envname}'";
    die "restart fail: $!" if system "$MYDan::PATH/AGENT/tools/restart";
    #TODO
    #die "Check fail: $!" if system "$MYDan::PATH/AGENT/tools/Check";
}
