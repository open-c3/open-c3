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

any '/default/auth/userauth' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $user = eval{ $api::mysql->query( "select name,level from `openc3_connector_userauth`", [ 'name', 'level' ] ) };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $user };
};

del '/default/auth/delauth' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new(
        user => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "delete from openc3_connector_userauth where name='$param->{user}'" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

post '/default/auth/addauth' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new(
        user => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
        level => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "replace into openc3_connector_userauth (`name`,`level`) values( '$param->{user}', '$param->{level}')" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

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
