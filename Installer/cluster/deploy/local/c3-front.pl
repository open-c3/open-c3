#!/data/Software/mydan/perl/bin/perl
use strict;
use warnings;
use MYDan;
use MYDan::Util::OptConf;

$| ++;

=head1 SYNOPSIS

 $0 --version 001

=cut

my $option = MYDan::Util::OptConf->load();
my %o = $option->get( qw( version=s domain=s ) )->dump();
$option->assert( qw( version ) );

unless( -e "$MYDan::PATH/c3-front" )
{
    die "mkdir $MYDan::PATH/c3-front fail" if system "mkdir -p '$MYDan::PATH/c3-front'";
}

die "rsync fail: $!" if system "rsync -av $MYDan::PATH/PKG/c3-front-$o{version}/ $MYDan::PATH/c3-front/dist/ --delete";
die "copy open-c3.org.conf fail: $!" if system "cp $MYDan::PATH/PKG/c3-front-$o{version}/nginxconf/open-c3.org.conf /etc/nginx/conf.d/";
die "copy open-c3.conf fail: $!" if system "cp $MYDan::PATH/PKG/c3-front-$o{version}/nginxconf/open-c3.conf /etc/nginx/conf.d/";
if( $o{domain}  )
{
    die "write domain fail: $!" if system "cat /etc/nginx/conf.d/open-c3.conf |sed 's/open-c3.org/$o{domain}/' > /etc/nginx/conf.d/open-c3.pri.conf";
}
die "reload nginx fail: $!"   if system "nginx -s reload";
