package api::userdepartment;
use Dancer ':syntax';
use Dancer qw(cookie);
use JSON qw();
use POSIX;
use api;
use uuid;
use Format;

get '/userdepartment' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my @col = qw( id user department edit_user edit_time );
    my $department = eval{ $api::mysql->query( sprintf( "select %s from `openc3_connector_userdepartment`", join( ',', @col ) ), \@col ) };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $department };
};

post '/userdepartment' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new( 
        user => qr/^[a-zA-Z0-9\.\@_\-]+$/, 1,
        department => qr/^[a-zA-Z0-9\.\@_\-]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','CREATE USERDEPARTMENT','USER:$param->{user} DEPARTMENT:$param->{department}')" ); };

    eval{ $api::mysql->execute( "replace into openc3_connector_userdepartment (`user`,`department`,`edit_user`) values('$param->{user}','$param->{department}', '$ssouser')" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, info => 'ok' };
};

del '/userdepartment/:id' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new( id => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my @col = qw( id user department edit_user edit_time );
    my $department = eval{ $api::mysql->query( sprintf( "select %s from `openc3_connector_userdepartment` where id='$param->{id}'", join( ',', @col ) ), \@col ) };

    return +{ stat => $JSON::false, info => "nofind the id" } unless $department && @$department > 0;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','DELETE USERADDR','USER:$department->[0]{user} DEPARTMENT:$department->[0]{department}')" ); };

    eval{ $api::mysql->execute( "delete from openc3_connector_userdepartment where id='$param->{id}'" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
