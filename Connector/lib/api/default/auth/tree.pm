package api::default::auth::tree;
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

any '/default/auth/tree/userauth' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $user = eval{ $api::mysql->query( "select id,name,tree,level from `openc3_connector_userauthtree`", [ 'id', 'name', 'tree', 'level' ] ) };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $user };
};

del '/default/auth/tree/delauth' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new(
        id => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "delete from openc3_connector_userauthtree where id='$param->{id}'" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

post '/default/auth/tree/addauth' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new(
        user  => qr/^[a-zA-Z0-9\@_\.\-]+$/, 1,
        tree  => qr/^\d+$/, 1,
        level => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "replace into openc3_connector_userauthtree (`name`,`tree`,`level`) values( '$param->{user}', '$param->{tree}','$param->{level}')" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
