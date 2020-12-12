#!/opt/mydan/perl/bin/perl
use strict;
use warnings;

use MYDan;
use MYDan::Util::OptConf;
use FindBin qw( $RealBin );

$| ++;

=head1 SYNOPSIS

 $0 --evnname txy 

=cut

my $option = MYDan::Util::OptConf->load();
my %o = $option->set() ->get( qw( envname=s ) )->dump(); 
$option->assert( qw( envname ) );

my $config = eval{ YAML::XS::LoadFile "/etc/open-c3.password" };
die "load open-c3.password fail: $@" if $@;
die "envname $o{envname} undef in open-c3.password" unless $config = $config->{$o{envname}};

my $BASE_PATH = "/data/open-c3";
my $MYDan_PATH = "/data/Software/mydan";

my $Config = eval{ YAML::XS::LoadFile "$BASE_PATH/JOB/config/Config" };
die "load Config fail: $@" if $@;
die "envname $o{envname} undef in Config" unless $Config = $Config->{$o{envname}};

die "envname $o{envname} nofind c3-database in $BASE_PATH/JOB/config/Config" unless my $ip = $Config->{"c3-database"};
my $mysql = $Config->{"mysql"};

unless( -f "$BASE_PATH/Installer/C3/mysql/init/init.sql" )
{
    system "cat $BASE_PATH/*/schema.sql > $BASE_PATH/Installer/C3/mysql/init/init.sql";
    system "cat $BASE_PATH/Installer/C3/mysql/init.sql >> $BASE_PATH/Installer/C3/mysql/init/init.sql";
}

die "rsync to $ip fail:$!\n" if system "sshpass -p '$config->{password}' rsync -av $BASE_PATH/Installer/ $config->{username}\@$ip:$MYDan_PATH/Installer/ --delete";
die "local.c3-database.pl to $ip fail:$!\n" if system "sshpass -p '$config->{password}' ssh $config->{username}\@$ip \"$MYDan_PATH/Installer/cluster/deploy/local/c3-database.pl --username '$mysql->{username}' --password '$mysql->{password}'\"";
