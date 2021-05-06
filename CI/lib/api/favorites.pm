package api::favorites;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;

post '/favorites/:groupid' => sub {
    my $param = params();
    my $error = Format->new( 
        ciid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ));
    return +{ stat => $JSON::false, code => 10000 } unless $user;

    eval{ $api::auditlog->run( user => $user, title => 'ADD FAVORITES', content => "FLOWLINEID:$param->{ciid} NAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{ 
        $api::mysql->execute( "replace into openc3_ci_favorites (`ciid`,`name`, `user` ) values( '$param->{ciid}', '$param->{name}', '$user' )");
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};


del '/favorites/:groupid' => sub {
    my $param = params();
    my $error = Format->new( 
        ciid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ));
    return +{ stat => $JSON::false, code => 10000 } unless $user;

    eval{ $api::auditlog->run( user => $user, title => 'DEL FAVORITES', content => "FLOWLINEID:$param->{ciid}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{ 
        $api::mysql->execute( "delete from openc3_ci_favorites where ciid='$param->{ciid}' and user='$user'" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
