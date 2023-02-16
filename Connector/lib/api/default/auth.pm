package api::default::auth;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use uuid;
use Format;
use Digest::MD5;
use point;

=pod

权限/获取用户角色列表

=cut

any '/default/auth/userauth' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $user = eval{ $api::mysql->query( "select name,level from `openc3_connector_userauth`", [ 'name', 'level' ] ) };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $user };
};

=pod

权限/删除权限

=cut

del '/default/auth/delauth' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new(
        user => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','DEL USER AUTH','user:$param->{user}')" ); };

    eval{ $api::mysql->execute( "delete from openc3_connector_userauth where name='$param->{user}'" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

权限/添加权限

=cut

post '/default/auth/addauth' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new(
        user => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
        level => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','CHANGE USER AUTH','user:$param->{user} level:$param->{level}')" ); };

    eval{ $api::mysql->execute( "replace into openc3_connector_userauth (`name`,`level`) values( '$param->{user}', '$param->{level}')" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

权限/通过权限点检查用户权限

该接口是系统内置的权限系统权限验证的接口。

如果C3启动使用的内置的权限系统，使用的就是该接口。

其它位置不要主动的调用它，/connectorx/point 接口会找到它进行调用。

属于后端模块使用的接口。

=cut

get '/default/auth/point' => sub {
    my $param = params();
    my $error = Format->new(
        point => qr/^[a-z0-9_]+$/, 1,
        treeid => qr/^\d+$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $cookie = $param->{cookie};
    return +{ stat => $JSON::false, info => "nofind cookie" } unless $cookie;
    my $user = eval{ $api::sso->run( cookie => $cookie ) };

    my ( $err, $s ) = point::point( $api::mysql, $param->{point}, $param->{treeid}, $user );
    return +{ stat => $JSON::true, info => $err } if $err;

    return +{ stat => $JSON::true, data => $s };
};

true;
