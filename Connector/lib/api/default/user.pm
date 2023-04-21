package api::default::user;
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

my ( $ssocookie, $passwordperiod );
BEGIN{
    $ssocookie = `c3mc-sys-ctl sys.sso.cookie`;
    chomp $ssocookie;

    $passwordperiod = `c3mc-sys-ctl sys.login.util.passwordperiod`;
    chomp $passwordperiod;
    $passwordperiod = 90 unless $passwordperiod && $passwordperiod =~ /^\d+$/;
};

=pod

系统内置/用户/获取用户列表

=cut

any '/default/user/userlist' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $user = eval{ $api::mysql->query( "select name,pass from `openc3_connector_userinfo`", [ 'name', 'pass' ] ) };
    return +{ stat => $JSON::false, info => $@ } if $@;
    map{ $_->{pass} = $_->{pass} ? ( $_->{pass} eq '4cb9c8a8048fd02294477fcb1a41191a' ? 2 : 1 ) : 0;}@$user;

    return +{ stat => $JSON::true, data => $user };

};

=pod

系统内置/用户/添加用户

=cut

post '/default/user/adduser' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new(
        user => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

   eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','ADD USER','USER:$param->{user}')" ); };

    eval{ $api::mysql->execute( "replace into openc3_connector_userinfo (`name`,`pass`,`sid`,`expire`) values( '$param->{user}', '4cb9c8a8048fd02294477fcb1a41191a', '', 0 )" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

系统内置/用户/删除用户

=cut

del '/default/user/deluser' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new(
        user => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','DEL USER','USER:$param->{user}')" ); };

    eval{ $api::mysql->execute( "delete from openc3_connector_userinfo where name='$param->{user}'" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

系统内置/用户/修改自己的密码

=cut

post '/default/user/chpasswd' => sub {
    my $param = params();
    my $error = Format->new(
        old => qr/^.+$/, 1,
        new1 => qr/^.+$/, 1,
        new2 => qr/^.+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    return  +{ stat => $JSON::false, info => "The two new passwords don't match" } unless $param->{new1} eq $param->{new2};

    my $cookie = cookie( $api::cookiekey );
    
    my $newmd5 = Digest::MD5->new->add($param->{new1})->hexdigest;
    my $oldmd5 = Digest::MD5->new->add($param->{old})->hexdigest;

    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','CHANGE PASSWD','-')" ); };

    my $x = eval{ $api::mysql->execute( "update openc3_connector_userinfo set pass='$newmd5' where sid='$cookie' and pass='$oldmd5'" ); };

    return +{ stat => $JSON::false, info => $@ } if $@;

    return $x eq 1 ? +{ stat => $JSON::true, info => $x } : +{ stat => $JSON::false, info => 'Password error' };
};

=pod

系统内置/用户/修改自己的密码/给审批前端使用

=cut

post '/default/approve/user/chpasswd' => sub {
    my $param = params();
    my $error = Format->new(
        old => qr/^.+$/, 1,
        new1 => qr/^.+$/, 1,
        new2 => qr/^.+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    return  +{ stat => $JSON::false, info => "The two new passwords don't match" } unless $param->{new1} eq $param->{new2};
    return  +{ stat => $JSON::false, info => "The password is too simple" }
        unless length $param->{new1} >= 8 && $param->{new1} =~ /[a-z]/  && $param->{new1} =~ /[A-Z]/  && $param->{new1} =~ /[0-9]/;

    my $cookie = cookie( $api::cookiekey );
    
    my $newmd5 = Digest::MD5->new->add($param->{new1})->hexdigest;
    my $oldmd5 = Digest::MD5->new->add($param->{old})->hexdigest;

    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','CHANGE APPROVE PASSWD','-')" ); };

    my $x = eval{ $api::mysql->execute( "update openc3_connector_userinfo set pass='$newmd5' where sid='$cookie' and pass='$oldmd5'" ); };

    return +{ stat => $JSON::false, info => $@ } if $@;

    return $x eq 1 ? +{ stat => $JSON::true, info => $x } : +{ stat => $JSON::false, info => 'Password error' };
};

=pod

系统内置/用户/获取用户基本信息

=cut

get '/internal/user/username' => sub {
    my $sid = params()->{cookie};
    return +{ stat => JSON::false, info => 'sid format err' } unless $sid && $sid =~ /^[a-zA-Z0-9]{64}$/;

    my $info = eval{ $api::mysql->query( sprintf "select name from `openc3_connector_userinfo` where sid='$sid'" ) };
    
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => +{}, info => 'Not logged in yet' } unless @$info;

    my $user = $info->[0][0];

    my $level = eval{ $api::mysql->query( "select level from openc3_connector_userauth where name='$user'" ) };
    my $userlevel = @$level ? $level->[0][0] : 0;

    return +{ stat => $JSON::true, data => +{ user => $user, company => $user =~ /(@.+)$/ ? $1 : 'default', admin => $userlevel >= 3 ? 1 : 0, showconnector => 1 }};
};

=pod

系统内置/用户/用户登出

=cut

any '/default/user/logout' => sub {

    my $sid = params()->{sid};
    $sid ||= cookie( $api::cookiekey );

    return +{ stat => $JSON::true, info => 'ok' } unless $sid;
    return +{ stat => $JSON::false, info => 'sid format err' } unless $sid =~ /^[a-zA-Z0-9]{64}$/;
    
    my $ip = '0.0.0.0';
    my $time = time;

    for( qw( HTTP_X_FORWARDED_FOR HTTP_X_REAL_IP REMOTE_ADDR ) )
    {
        my $x = request->env->{$_};
        if( $x && $x =~ /^\s*(\d+\.\d+\.\d+\.\d+)\b/ )
        {
            $ip = $1;
            last;
        }
    }

    eval{ $api::mysql->execute( "insert into openc3_connector_user_login_audit( `user`,`uuid`,`action`,`ip`,`t` ) ( select name, '','logout','$ip','$time' from openc3_connector_userinfo where sid='$sid' )" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{ $api::mysql->execute( "update openc3_connector_userinfo set expire=0,sid='' where sid='$sid'" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    return +{ stat => $JSON::true, info => 'ok' };
};

=pod

系统内置/用户/用户登录

=cut

any '/default/user/login' => sub {
    my $param = params();
    my $error = Format->new(
        user => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $pass, $domain, $err ) = @$param{qw( user pass domain )};

    return +{ stat => $JSON::false, info => 'user or pass undef' }
        unless defined $user & defined $pass;

    $pass = encode_base64( $pass );
    my $x = `c3mc-login --user '$user' --pass '$pass'`;
    chomp $x;
    if( $x eq 'ok' )
    {
        my @chars = ( "A" .. "Z", "a" .. "z", 0 .. 9 );
        my $keys = join("", @chars[ map { rand @chars } ( 1 .. 64 ) ]);
        eval{ $api::mysql->execute( sprintf "update openc3_connector_userinfo set expire=%d,sid='%s' where name='%s'", time + 7 * 86400, $keys, $user ); };
        return +{ stat => $JSON::false, info => $@ } if $@;

        my %domain;
        if( $ssocookie && $domain && $domain =~ /[a-z]/ )
        {
            my @x = reverse split /\./, $domain;
            %domain = ( domain => ".$x[1].$x[0]") if @x >= 3;
        }

        set_cookie( $api::cookiekey => $keys, http_only => 0, expires => time + 8 * 3600, %domain );

        my $ip = '0.0.0.0';
        my $time = time;

        for( qw( HTTP_X_FORWARDED_FOR HTTP_X_REAL_IP REMOTE_ADDR ) )
        {
            my $x = request->env->{$_};
            if( $x && $x =~ /^\s*(\d+\.\d+\.\d+\.\d+)\b/ )
            {
                $ip = $1;
                last;
            }
        }
        my $uuid = Digest::MD5->new->add($pass)->hexdigest;

        eval{ $api::mysql->execute( "insert into openc3_connector_user_login_audit( `user`,`uuid`,`action`,`ip`,`t` ) values('$user','$uuid','login','$ip','$time')" ); };
        return +{ stat => $JSON::false, info => $@ } if $@;

        my $f = eval{ $api::mysql->query( "select t from `openc3_connector_user_login_audit` where user='$user' and uuid='$uuid' and action='login' order by id limit 1" ) };
        return +{ stat => $JSON::false, info => $@ } if $@;

        my $ftime = $f && @$f ? $f->[0][0] : time - 60;

        return +{ stat => $JSON::false, info => "Error. password period." } if $ftime + $passwordperiod * 86400 < time;

        return +{ stat => $JSON::true, info => 'ok' };
    }
    else
    {
        return +{ stat => $JSON::false, info => "Error. " . $x };
    }

};

true;
