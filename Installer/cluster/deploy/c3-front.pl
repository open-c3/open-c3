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

my $option = MYDan::Util::OptConf->load();
my %o = $option->set() ->get( qw( envname=s version=s rollback hostname=s ) )->dump();
$option->assert( qw( envname ) );

my $config = eval{ YAML::XS::LoadFile "/etc/open-c3.password" };
die "load open-c3.password fail: $@" if $@;
die "envname $o{envname} undef in open-c3.password" unless $config = $config->{$o{envname}};

my $BASE_PATH = "/data/open-c3";
my $MYDan_PATH = "/data/Software/mydan";

my $Config = eval{ YAML::XS::LoadFile "$BASE_PATH/JOB/config/Config" };
die "load Config fail: $@" if $@;
die "envname $o{envname} undef in Config" unless $Config = $Config->{$o{envname}};

my @host = sort keys %{$Config->{host}};
@host = grep{ $_ =~ /$o{hostname}/ }@host if $o{hostname};
my @ip;map{ my $host = $Config->{host}{$_}; push @ip, $host->{exip} || $host->{inip}; }@host;

unless( $o{version} )
{
    map { die "show version to $_ fail:$!\n" if system "sshpass -p '$config->{password}' ssh $config->{username}\@$_ 'cd $MYDan_PATH/PKG/&& ls |sort|grep ^c3-front-|grep -v web-shell'"; }@ip;
    exit;
}

map { die "rsync to $_ fail:$!\n" if system "sshpass -p '$config->{password}' rsync -av $BASE_PATH/Installer/ $config->{username}\@$_:$MYDan_PATH/Installer/ --delete"; }@ip;

map
{
    die "rsync to $_ fail:$!\n" if system "sshpass -p '$config->{password}' rsync -av $BASE_PATH/c3-front/dist/ $config->{username}\@$_:$MYDan_PATH/PKG/c3-front-$o{version}/ --delete";
}@ip unless $o{rollback};

my $domain = $ENV{C3_DOMAIN} ? "--domain $ENV{C3_DOMAIN}"  : "";
map
{
    die "rsync to $_ fail:$!\n" if system "sshpass -p '$config->{password}' rsync -av $BASE_PATH/c3-front/nginxconf/ $config->{username}\@$_:$MYDan_PATH/PKG/c3-front-$o{version}/nginxconf/";
    die "local.c3-front.pl to $_ fail:$!\n" if system "sshpass -p '$config->{password}' ssh $config->{username}\@$_ '$MYDan_PATH/Installer/cluster/deploy/local/c3-front.pl' -v '$o{version}' $domain";
}@ip;

