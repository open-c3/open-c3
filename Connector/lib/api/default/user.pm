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

any '/default/user/userlist' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $user = eval{ $api::mysql->query( "select name,pass from `openc3_connector_userinfo`", [ 'name', 'pass' ] ) };
    return +{ stat => $JSON::false, info => $@ } if $@;
    map{ $_->{pass} = $_->{pass} eq '4cb9c8a8048fd02294477fcb1a41191a' ? 1 : 0;}@$user;

    return +{ stat => $JSON::true, data => $user };

};

post '/default/user/adduser' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new(
        user => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "replace into openc3_connector_userinfo (`name`,`pass`,`sid`,`expire`) values( '$param->{user}', '4cb9c8a8048fd02294477fcb1a41191a', '', 0 )" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

del '/default/user/deluser' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new(
        user => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "delete from openc3_connector_userinfo where name='$param->{user}'" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

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

    my $x = eval{ $api::mysql->execute( "update openc3_connector_userinfo set pass='$newmd5' where sid='$cookie' and pass='$oldmd5'" ); };

    return +{ stat => $JSON::false, info => $@ } if $@;

    return $x eq 1 ? +{ stat => $JSON::true, info => $x } : +{ stat => $JSON::false, info => 'Password error' };
};

get '/internal/user/username' => sub {
    my $sid = params()->{cookie};
    return +{ stat => JSON::false, info => 'sid format err' } unless $sid && $sid =~ /^[a-zA-Z0-9]{64}$/;

    my $info = eval{ $api::mysql->query( sprintf "select name from `openc3_connector_userinfo` where sid='$sid'" ) };
    
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => JSON::false, info => 'Not logged in yet' } unless @$info;

    my $user = $info->[0][0];

    my $level = eval{ $api::mysql->query( "select level from openc3_connector_userauth where name='$user'" ) };
    my $userlevel = @$level ? $level->[0][0] : 0;

    return +{ stat => JSON::true, data => +{ user => $user, company => $user =~ /(@.+)$/ ? $1 : 'default', admin => $userlevel >= 3 ? 1 : 0, showconnector => 1 }};
};

any '/default/user/logout' => sub {

    my $sid = params()->{sid};
    $sid ||= cookie( "sid" );

    return +{ stat => $JSON::true, info => 'ok' } unless $sid;
    return +{ stat => $JSON::false, info => 'sid format err' } unless $sid =~ /^[a-zA-Z0-9]{64}$/;
    eval{ $api::mysql->execute( "update openc3_connector_userinfo set expire=0,sid='' where sid='$sid'" ); };
    
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, info => 'ok' };
};


any '/default/user/login' => sub {
    my $param = params();
    my ( $user, $pass, $err ) = @$param{qw( user pass )};

    return +{ stat => $JSON::false, info => 'user or pass undef' }
        unless defined $user & defined $pass;

    my $info = eval{ $api::mysql->query( sprintf "select name from openc3_connector_userinfo where name='$user' and pass='%s'",  Digest::MD5->new->add($pass)->hexdigest ) };

    return +{ stat => $JSON::false, info => $@ } if $@;
    if( @$info )
    {
        my @chars = ( "A" .. "Z", "a" .. "z", 0 .. 9 );
        my $keys = join("", @chars[ map { rand @chars } ( 1 .. 64 ) ]);
        eval{ $api::mysql->execute( sprintf "update openc3_connector_userinfo set expire=%d,sid='%s' where name='%s'", time + 8 * 3600, $keys, $user ); };
        return +{ stat => $JSON::false, info => $@ } if $@;

        set_cookie( sid => $keys, http_only => 0, expires => time + 8 * 3600 );
        return +{ stat => $JSON::true, info => 'ok' };
    }
    else
    {
        return +{ stat => $JSON::false, info => 'Incorrect user password!!!' };
    }

};

true;
