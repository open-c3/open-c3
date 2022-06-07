package api::cloudmon;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use Encode qw(decode encode);

get '/cloudmon' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my @col = qw( id name type describe edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_cloudmon", join( ',', map{"`$_`"}@col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

get '/cloudmon/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my @col = qw( id name type describe config edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_cloudmon where id='$param->{id}'", join( ',', map{"`$_`"}@col)), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{ $r->[0]{config} = decode("UTF-8", decode_base64( $r->[0]{config} ) ) if $r && @$r; };
    return +{ stat => $JSON::false, info => $@ } if $@;

    return +{ stat => $JSON::true, data => ( $r && @$r ) ? $r->[0] : +{} };
};

post '/cloudmon' => sub {
    my $param = params();
    my $error = Format->new( 
        id       => qr/^\d+$/, 0,
        name     => [ 'mismatch', qr/'/ ], 1,
        type     => [ 'mismatch', qr/'/ ], 1, #TODO
        describe => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $title = $param->{id} ? "EDIT" : "ADD";
    eval{ $api::auditlog->run( user => $user, title => "$title CLOUDMON", content => "name:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $config = encode_base64( encode('UTF-8', $param->{config}) );

    my $r = eval{ 
        $api::mysql->execute(
           $param->{id}
              ? "update openc3_monitor_cloudmon set name='$param->{name}',type='$param->{type}',`describe`='$param->{describe}',config='$config' where id='$param->{id}'"
              : "insert into openc3_monitor_cloudmon (`name`,`type`,`describe`,`config`)values( '$param->{name}','$param->{type}','$param->{describe}','$config')"
         )
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

del '/cloudmon/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'DEL CLOUDMON', content => "ID:$param->{id}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ $api::mysql->execute( "delete from openc3_monitor_cloudmon where id='$param->{id}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
