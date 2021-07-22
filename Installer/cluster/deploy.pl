#!/opt/mydan/perl/bin/perl
use strict;
use warnings;

use MYDan;
use MYDan::Util::OptConf;
use FindBin qw( $RealBin );

$| ++;

=head1 SYNOPSIS

 $0 --evnname txy 
 $0 --evnname txy --version 001
 $0 --evnname txy --version 001 --rollback
 $0 --evnname txy --version 001 --hostname 'foo'

=cut

my $argv = join ' ', @ARGV;
my $option = MYDan::Util::OptConf->load();
my %o = $option->set()
    ->get( qw( envname=s version=s rollback hostname=s ) )->dump();

$option->assert( qw( envname ) );

map{
    die "deploy $_ fail." if system "$RealBin/deploy/$_.pl $argv";
}qw( Connector AGENT CI JOB JOBX c3-front web-shell MYDan );
