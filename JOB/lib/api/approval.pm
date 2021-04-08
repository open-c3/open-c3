package api::approval;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;
use Util;


get '/approval' => sub {
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my @col = qw( id taskuuid uuid name opinion remarks create_time finishtime submitter oauuid notifystatus );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from approval
                where user='$user' order by id desc limit 100", join( ',', @col ) ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => $r };
};

post '/approval' => sub {
    my $param = params();
    my $error = Format->new( 
        opinion => [ 'in', 'agree', 'refuse' ], 1,
        uuid => qr/^[a-zA-Z0-9]{12}$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'USR APPROVAL', content => "UUID:$param->{uuid} OPINION:$param->{opinion}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $r = eval{ $api::mysql->execute( "update approval set opinion='$param->{opinion}',finishtime='$time' where uuid='$param->{uuid}' and user='$user' and opinion='unconfirmed'")};

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

get '/approval/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]{12}$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my @col = qw( id taskuuid name cont opinion remarks create_time finishtime submitter oauuid notifystatus user );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from approval
                where taskuuid in ( select taskuuid from approval where user='$user' and uuid='$param->{uuid}')", join( ',', @col ) ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => $r };
};

get '/approval/control/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]{12}$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my @col = qw( id taskuuid name cont opinion remarks create_time finishtime submitter oauuid notifystatus user );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from approval
                where taskuuid in ( select taskuuid from approval where uuid='$param->{uuid}')", join( ',', @col ) ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => $r };
};

get '/approval/control/status/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]{12}$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my @col = qw( id taskuuid uuid name cont opinion remarks create_time finishtime submitter oauuid notifystatus user );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from approval where uuid='$param->{uuid}' ", join( ',', @col ) ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => @$r ? $r->[0] : +{} };
};


post '/approval/control' => sub {
    my $param = params();
    my $error = Format->new( 
        opinion => [ 'in', 'agree', 'refuse' ], 1,
        uuid => qr/^[a-zA-Z0-9]{12}$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::auditlog->run( user => 'openapi', title => 'KEY APPROVAL', content => "UUID:$param->{uuid} OPINION:$param->{opinion}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $r = eval{ $api::mysql->execute( "update approval set opinion='$param->{opinion}',finishtime='$time' where uuid='$param->{uuid}' and opinion='unconfirmed'")};

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

true;
