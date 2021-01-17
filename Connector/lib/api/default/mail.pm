package api::default::mail;
use Dancer ':syntax';
use Dancer qw(cookie);

use JSON;
use POSIX;
use api;
use uuid;
use Format;

get '/default/mail' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $mesg = eval{ $api::mysql->query( "select time,title,content from `usermail` where user = '$ssouser' order by id desc limit 100", [ 'time', 'title', 'content' ] ) };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $mesg };
};

post '/default/mail' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $param = params();
    my $error = Format->new( 
        user => qr/^[a-zA-Z0-9\.\@_\-]+$/, 1,
        title => qr/.+/, 1,
        content => qr/.+/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "insert into usermail (`user`,`title`,`content`) values('$param->{user}','$param->{title}','$param->{content}')" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, info => 'ok' };
};

true;
