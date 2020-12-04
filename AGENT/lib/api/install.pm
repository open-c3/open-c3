package api::install;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON;
use POSIX;
use MIME::Base64;
use api;
use uuid;
use Format;
use keepalive;

get '/install/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( id uuid projectid regionid type user status starttime runtime slave success fail );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from install
                where projectid='$projectid' order by id desc", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};


get '/install/:projectid/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( ip starttime finishtime status reason );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from install_detail where uuid in (select uuid from install where projectid='$param->{projectid}' and uuid='$param->{uuid}')", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};



post '/install/:projectid/:regionid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        regionid => qr/^\d+$/, 1,
  
        ip => qr/^[a-zA-Z0-9 \-\._,]+$/, 1,
        type => qr/^[a-z_]+$/, 1,

        username => qr/^[a-zA-Z0-9\-]+$/, 0,
        password => qr/^.*$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $slave = eval{ keepalive->new( $api::mysql )->slave() };
    return  +{ stat => $JSON::false, info => "get slave fail: $@" } if $@;


    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $username = $param->{username} || 'root';

    my $password = $param->{password} ? encode_base64( encode('UTF-8',  $param->{password}) ) : '';
    my $uuid = uuid->new()->create_str;
    my $r = eval{ 
        $api::mysql->execute(
            "insert into install (`uuid`,`projectid`,`slave`,`regionid`,`ip`,`type`,`user`,`username`,`password`,`status`)
                values( '$uuid','$param->{projectid}','$slave','$param->{regionid}','$param->{ip}','$param->{type}','$user','$username','$password', 'init')")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, uuid => $uuid };
};

true;
