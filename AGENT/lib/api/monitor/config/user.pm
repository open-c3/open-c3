package api::monitor::config::user;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

=pod

监控系统/告警接收人/获取列表

=cut

get '/monitor/config/user/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( id user edit_user edit_time subgroup );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_user
                where projectid='$projectid'", join( ',', map{ "`$_`" }@col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

监控系统/告警接收人/获取详情

=cut

get '/monitor/config/user/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( id user edit_user edit_time subgroup );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_user where projectid='$projectid' and id='$param->{id}'", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0] };
};

=pod

监控系统/告警接收人/创建或编辑接收人

=cut

post '/monitor/config/user/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 0,
        user => [ 'mismatch', qr/'/ ], 1,
        subgroup => qr/^[a-zA-Z0-9]*$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my ( $id, $projectid, $subgroup ) = @$param{qw( id projectid subgroup )};

    eval{
        my $title = $id ? "UPDATE" : "ADD";
        $api::auditlog->run( user => $user, title => "$title MONITOR CONFIG USER", content => "TREEID:$projectid USER:$param->{user} SUBGROUP:$subgroup" );
        if( $param->{id} )
        {
            $api::mysql->execute( "update openc3_monitor_config_user set `user`='$param->{user}',edit_user='$user',subgroup='$subgroup' where projectid='$projectid' and id='$id'" );
        }
        else
        {
            $api::mysql->execute( "insert into openc3_monitor_config_user (`projectid`,`user`,`edit_user`,`subgroup`) values('$projectid','$param->{user}','$user','$subgroup')" );
        }
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

监控系统/告警接收人/删除接收人

=cut

del '/monitor/config/user/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $cont = eval{ $api::mysql->query( "select `user` from openc3_monitor_config_user where id='$param->{id}'")};
    eval{ $api::auditlog->run( user => $user, title => 'DEL MONITOR CONFIG USER', content => "TREEID:$param->{projectid} USER:$cont->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "delete from openc3_monitor_config_user where id='$param->{id}' and projectid='$param->{projectid}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

监控系统/告警接收人/测试消息通道

回给接收人发送消息，测试一下接收人是否可以正常收到告警消息。

消息包括邮件、短信、电话。

=cut

post '/monitor/config/usertest' => sub {
    my $param = params();
    my $error = Format->new( 
        user      => [ 'mismatch', qr/'/ ], 1,
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $usr = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    eval{ $api::auditlog->run( user => $usr, title => 'Monitor Test User', content => "TREE:$param->{project} USER:$param->{user}" ); };

    my $user = $param->{user};

    return +{ stat => $JSON::false, info => "user format error" } unless $user && $user =~ /^[a-zA-Z0-9@\.\-_:%]+$/;

    eval{
        die "send mesg fail: $!" if system "c3mc-app-usrext '$user' | xargs -i{} bash -c \"cat /data/Software/mydan/AGENT/config/mesgsendtest.txt |sed 's/XXX/{}/' | c3mc-base-send \"";
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
