#!/opt/mydan/perl/bin/perl
use strict;
use warnings;
use YAML::XS;

$| ++;

die "$0 envname\n" unless my $envname = shift @ARGV;
my $BASE_PATH = "/data/open-c3";

sub loadconfig
{
    my ( $envname, $modle ) = @_;
    my $file = "$BASE_PATH/$modle/config/Config";
    my $conf = eval{ YAML::XS::LoadFile $file };
    die "load $file: $@" if $@;

    die "nofind envname $envname in $file" unless my $c = $conf->{$envname};
    return %{$c->{host}};
}

my %host;
for( qw( CI AGENT JOB JOBX Connector ) )
{
    %host = ( %host, loadconfig( $envname, $_ ) );
}

my ( @inip, @exip, %hostname );
for( sort keys %host )
{
    my $v = $host{$_};
    push @inip, $v->{inip} || $v->{exip};
    push @exip, $v->{exip} || $v->{inip};
    $hostname{$v->{exip} || $v->{inip}} = $_;
}

if( 1 < @inip && ! -d "$BASE_PATH/Installer/cluster/init/glusterfs/conf/$envname" )
{
    my $type = @inip >= 4 ? 4 : 2;
    die "copy fail: $!" if system "rsync -av $BASE_PATH/Installer/cluster/init/glusterfs/conf.template/type$type/ $BASE_PATH/Installer/cluster/init/glusterfs/conf/$envname/";
    for( 0 .. $#inip )
    {
        my ( $ip, $id ) = ( $inip[$_], $_ + 1 );
        system "sed -i 's/OPENC3HOST$id/$ip/g' $BASE_PATH/Installer/cluster/init/glusterfs/conf/$envname/glusterfs.vol";
    }
    my $c = `cat $BASE_PATH/Installer/cluster/init/glusterfs/conf/$envname/glusterfs.vol`;
    die "config error.find OPENC3HOST" if $c =~ /OPENC3HOST/;
}

sub inithost
{
    my ( $envname, $ip ) = @_; 
    my $config = eval{ YAML::XS::LoadFile "/etc/open-c3.password" };
    die "load password from /etc/open-c3.password fail: $@" if $@;
    die "envname $envname undef in open-c3.password\n" unless $config = $config->{$envname};

    die "mkdir /data/Software/mydan fail:$!\n" if system "sshpass -p '$config->{password}' ssh -o StrictHostKeyChecking=no $config->{username}\@$ip 'mkdir -p /data/Software/mydan'";
    die "create /data/Software/mydan/.open-c3.hostname fail:$!\n" if system "sshpass -p '$config->{password}' ssh -o StrictHostKeyChecking=no $config->{username}\@$ip 'echo $hostname{$ip} > /data/Software/mydan/.open-c3.hostname'";
    die "rsync to $ip fail:$!\n" if system "sshpass -p '$config->{password}' rsync -av $BASE_PATH/Installer/ $config->{username}\@$ip:/data/Software/mydan/Installer/";
    die "mkdir /data/Software/mydan fail:$!\n" if system "sshpass -p '$config->{password}' ssh $config->{username}\@$ip 'cd /data/Software/mydan/Installer/cluster && ./init.sh $envname $config->{username}'";
}

map{ inithost( $envname, $_ ) }@exip;
