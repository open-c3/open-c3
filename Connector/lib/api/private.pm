package api::private;
use Dancer ':syntax';
use Dancer qw(cookie);
use JSON qw();
use POSIX;
use api;
use uuid;
use Format;

=pod

私有节点/获取私有节点列表

=cut

get '/private' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my @col = qw( id user edit_user edit_time );
    my $addr = eval{ $api::mysql->query( sprintf( "select %s from `openc3_connector_private` order by id desc", join( ',', @col ) ), \@col ) };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $addr };
};

=pod

私有节点/添加私有节点

=cut

post '/private' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $param = params();
    my $error = Format->new( 
        user => qr/^[a-zA-Z0-9\.\@_\-]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','ADD PRIVATE','USER:$param->{user}')" ); };

    $param->{user} =~ s/\./_/g;
    eval{ $api::mysql->execute( "insert into openc3_connector_private (`user`,`edit_user`) values('$param->{user}', '$ssouser')" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, info => 'ok' };
};

true;
