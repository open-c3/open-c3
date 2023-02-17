package api::default::mesg;
use Dancer ':syntax';
use Dancer qw(cookie);

use JSON qw();
use POSIX;
use api;
use uuid;
use Format;

=pod

系统内置/短信/获取短信列表

=cut

get '/default/mesg' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $mesg = eval{ $api::mysql->query( "select time,mesg from `openc3_connector_usermesg` where user = '$ssouser' order by id desc limit 100", [ 'time', 'mesg' ] ) };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $mesg };
};

=pod

系统内置/短信/发送短信

注：属于内置接口，只有后端模块可能会调用。

=cut

post '/default/mesg' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $param = params();
    my $error = Format->new( 
        user => qr/^[a-zA-Z0-9\.\@_\-]+$/, 1,
        mesg => qr/.+/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    $param->{mesg} =~ s/'/"/g;

    eval{ $api::mysql->execute( "insert into openc3_connector_usermesg (`user`,`mesg`) values('$param->{user}','$param->{mesg}')" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, info => 'ok' };
};

true;
