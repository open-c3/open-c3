package api::sysctl;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use Util;
use uuid;
use FindBin qw( $RealBin );
use File::Basename;
use POSIX;
use OPENC3::SysCtl;

=pod

系统设置/获取设置信息

=cut

get '/sysctl' => sub
{
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck('openc3_connector_root'); return $pmscheck if $pmscheck;
    my $config = OPENC3::SysCtl->new()->dump();
    return +{ stat => $JSON::true, data => $config };
};

=pod

系统设置/获取节点名称

集群中的每台机器都有一个唯一的名称，这个接口可以查询当前相应请求的节点的名称。

=cut

get '/sysctl/hostname' => sub
{
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck('openc3_connector_root'); return $pmscheck if $pmscheck;
    return +{ stat => $JSON::true, data => `c3mc-base-hostname` };
};

=pod

系统设置/编辑设置

=cut

post '/sysctl' => sub
{
    my $param  = params();
    my $config = params()->{config};
    return +{ stat => $JSON::false, info => 'nofind config in params' } unless $config;

    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck('openc3_connector_root'); return $pmscheck if $pmscheck;

    my $time = POSIX::strftime( "%Y%m%d%H%M%S", localtime );

    eval {
        $api::mysql->execute(
            "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','EDIT CONNECTOR SYSCTL','_')"
        );
    };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval {
        YAML::XS::DumpFile "/data/open-c3-data/sysctl.conf", $config;
        my $backup = "/data/open-c3-data/sysctl.backup";
        unless ( -d $backup ) {
            die "mkdir backup path fail: $!" if system "mkdir -p '$backup'";
        }
        die "copy config fail: $!" if system "cp /data/open-c3-data/sysctl.conf $backup/sysctl.conf.$time";
    };
    return $@ ? +{ stat => $JSON::false, info => "dump config fail:$@" } : +{ stat => $JSON::true, info => 'ok' };
};

true;
