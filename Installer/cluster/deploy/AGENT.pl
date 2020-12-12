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

my $Config = eval{ YAML::XS::LoadFile "$BASE_PATH/AGENT/config/Config" };
die "load Config fail: $@" if $@;
die "envname $o{envname} undef in Config" unless $Config = $Config->{$o{envname}};

my @host = sort keys %{$Config->{host}};
@host = grep{ $_ =~ /$o{hostname}/ }@host if $o{hostname};
my @ip;map{ my $host = $Config->{host}{$_}; push @ip, $host->{exip} || $host->{inip}; }@host;

unless( $o{version} )
{
    map { die "show version to $_ fail:$!\n" if system "sshpass -p '$config->{password}' ssh -o StrictHostKeyChecking=no $config->{username}\@$_ 'cd $MYDan_PATH/PKG/&& ls |sort|grep ^AGENT-'"; }@ip;
    exit;
}

map { die "rsync to $_ fail:$!\n" if system "sshpass -p '$config->{password}' rsync -av $BASE_PATH/Installer/ $config->{username}\@$_:$MYDan_PATH/Installer/ --delete"; }@ip;

map { die "rsync to $_ fail:$!\n" if system "sshpass -p '$config->{password}' rsync -av $BASE_PATH/AGENT/ $config->{username}\@$_:$MYDan_PATH/PKG/AGENT-$o{version}/ --exclude conf/ --delete"; }@ip unless $o{rollback};

system "mkdir -p /etc/open-c3/key" unless -d "/etc/open-c3/key";
unless( -f "/etc/open-c3/key/c3_$o{envname}.pub" && -f "/etc/open-c3/key/c3_$o{envname}.key" )
{
    unlink "/etc/open-c3/key/c3_$o{envname}.pub", "/etc/open-c3/key/c3_$o{envname}.key";
    die "create sshkey fail:$!" if system "cd /etc/open-c3/key && ssh-keygen -f c3_$o{envname} -P '' && mv 'c3_$o{envname}' 'c3_$o{envname}.key'";
}

map
{
    die "rsync pub to $_ fail:$!\n" if system "sshpass -p '$config->{password}' rsync -av /etc/open-c3/key/c3_$o{envname}.pub $config->{username}\@$_:$MYDan_PATH/etc/agent/auth/";
    die "rsync key to $_ fail:$!\n" if system "sshpass -p '$config->{password}' rsync -av /etc/open-c3/key/c3_$o{envname}.key $config->{username}\@$_:$MYDan_PATH/etc/agent/auth/";
    die "local.AGENT.pl to $_ fail:$!\n" if system "sshpass -p '$config->{password}' ssh $config->{username}\@$_ '$MYDan_PATH/Installer/cluster/deploy/local/AGENT.pl' -e '$o{envname}' -v '$o{version}'";
}@ip;
