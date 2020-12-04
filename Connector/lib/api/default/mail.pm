package api::default::mail;
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

get '/default/mail' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $mesg = eval{ $api::mysql->query( "select time,title,content from `usermail` where user = '$ssouser' order by id desc limit 100", [ 'time', 'title', 'content' ] ) };

    map{
        $_->{title} = decode_base64( $_->{title});
        $_->{content} = decode_base64( $_->{content});
    }@$mesg;

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

    my $title = encode_base64( $param->{title} );
    my $content = encode_base64( $param->{content} );

    eval{ $api::mysql->execute( "insert into usermail (`user`,`title`,`content`) values('$param->{user}','$title','$content')" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, info => 'ok' };
};

true;
