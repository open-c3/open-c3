package api::useraddr;
use Dancer ':syntax';
use Dancer qw(cookie);
use JSON qw();
use POSIX;
use api;
use uuid;
use Format;

get '/useraddr' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my @col = qw( id user email phone edit_user edit_time );
    my $addr = eval{ $api::mysql->query( sprintf( "select %s from `openc3_connector_useraddr`", join( ',', @col ) ), \@col ) };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $addr };
};

post '/useraddr' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new( 
        user => qr/^[a-zA-Z0-9\.\@_\-]+$/, 1,
        email => qr/^[a-zA-Z0-9\.\@_\-]+$/, 1,
        phone => qr/^[a-zA-Z0-9\.\@_\-]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','CREATE USERADDR','USER:$param->{user} EMAIL:$param->{email} PHONE:$param->{phone}')" ); };

    eval{ $api::mysql->execute( "replace into openc3_connector_useraddr (`user`,`email`,`phone`,`edit_user`) values('$param->{user}','$param->{email}','$param->{phone}', '$ssouser')" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, info => 'ok' };
};

del '/useraddr/:id' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new( id => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my @col = qw( id user email phone edit_user edit_time );
    my $addr = eval{ $api::mysql->query( sprintf( "select %s from `openc3_connector_useraddr` where id='$param->{id}'", join( ',', @col ) ), \@col ) };

    return +{ stat => $JSON::false, info => "nofind the id" } unless $addr && @$addr > 0;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','DELETE USERADDR','USER:$addr->[0]{user} EMAIL:$addr->[0]{email} PHONE:$addr->[0]{phone}')" ); };

    eval{ $api::mysql->execute( "delete from openc3_connector_useraddr where id='$param->{id}'" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
