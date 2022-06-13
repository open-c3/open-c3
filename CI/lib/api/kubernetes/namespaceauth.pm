package api::kubernetes::namespaceauth;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

get '/kubernetes/namespaceauth/:ticketid' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid  => qr/^\d+$/, 1,
        namespace => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $company ) = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $check = eval{
        $api::mysql->query(
            "select id from openc3_ci_ticket where create_user='$user' or edit_share='$user' or edit_share like '%%,$user,%%' or edit_share like '$user,%%' or edit_share like '%%,$user'"
        )
    };
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::false, info => 'no auth' } unless $check && @$check;

    my $and = $param->{namespace} ? "and namespace='$param->{namespace}'" : "";
    my @col = qw( id ticketid namespace user auth  edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_k8s_namespace_auth where ticketid='$param->{ticketid}' $and", join( ',', map{"`$_`"}@col)), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true,  data => $r };
};

post '/kubernetes/namespaceauth/:ticketid' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid  => qr/^\d+$/, 1,
        namespace => [ 'mismatch', qr/'/ ], 1,
        user      => [ 'mismatch', qr/'/ ], 1,
        auth      => [ 'in', 'r', 'rw' ], 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $company ) = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $check = eval{
        $api::mysql->query(
            "select id from openc3_ci_ticket where create_user='$user' or edit_share='$user' or edit_share like '%%,$user,%%' or edit_share like '$user,%%' or edit_share like '%%,$user'"
        )
    };
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::false, info => 'no auth' } unless $check && @$check;

    eval{ $api::auditlog->run( user => $user, title => 'CREATE NAMESPACEAUTH', content => "TICKETID:$param->{ticketid} NAMESPACE:$param->{namespace} USER:$param->{user} auth:$param->{auth}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    eval{ 
        $api::mysql->execute( "replace into openc3_ci_k8s_namespace_auth (`ticketid`, `namespace`,`user`,`auth`,`edit_user`,`edit_time` )
            values( '$param->{ticketid}', '$param->{namespace}', '$param->{user}', '$param->{auth}', '$user', '$time' )");
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

del '/kubernetes/namespaceauth/:ticketid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        id       => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $user, $company ) = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $check = eval{
        $api::mysql->query(
            "select id from openc3_ci_ticket where create_user='$user' or edit_share='$user' or edit_share like '%%,$user,%%' or edit_share like '$user,%%' or edit_share like '%%,$user'"
        )
    };
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::false, info => 'no auth' } unless $check && @$check;

    eval{ $api::auditlog->run( user => $user, title => 'DELETE NAMESPACEAUTH', content => "TICKETID:$param->{ticketid} ID:$param->{id}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $update = eval{ 
        $api::mysql->execute( "delete from openc3_ci_k8s_namespace_auth where id='$param->{id}' and ticketid='$param->{ticketid}'" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : $update ? +{ stat => $JSON::true } : +{ stat => $JSON::false, info => 'not delete' };
};

true;
