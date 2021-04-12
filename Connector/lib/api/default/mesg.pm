package api::default::mesg;
use Dancer ':syntax';
use Dancer qw(cookie);

use JSON;
use POSIX;
use api;
use uuid;
use Format;

get '/default/mesg' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $mesg = eval{ $api::mysql->query( "select time,mesg from `usermesg` where user = '$ssouser' order by id desc limit 100", [ 'time', 'mesg' ] ) };

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

    $param->{mesg} =~ s/'/"/g;

    eval{ $api::mysql->execute( "insert into usermesg (`user`,`mesg`) values('$param->{user}','$param->{mesg}')" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, info => 'ok' };
};

true;
