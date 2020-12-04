package api::default::mesg;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON;
use POSIX;
use MIME::Base64;
use api;
use uuid;
use Format;
use Digest::MD5;

get '/default/mesg' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $mesg = eval{ $api::mysql->query( "select time,mesg from `usermesg` where user = '$ssouser' order by id desc limit 100", [ 'time', 'mesg' ] ) };
    map{ $_->{mesg} = decode_base64( $_->{mesg}); }@$mesg;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $mesg };
};

post '/default/mesg' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $param = params();
    my $error = Format->new( 
        user => qr/^[a-zA-Z0-9\.\@_\-]+$/, 1,
        mesg => qr/.+/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $mesg = encode_base64( $param->{mesg} );

    eval{ $api::mysql->execute( "insert into usermesg (`user`,`mesg`) values('$param->{user}','$mesg')" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, info => 'ok' };
};

true;
