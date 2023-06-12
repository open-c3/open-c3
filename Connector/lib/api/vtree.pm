package api::vtree;
use Dancer ':syntax';
use Dancer qw(cookie);
use JSON qw();
use POSIX;
use api;
use uuid;
use Format;

=pod

虚拟服务树/服务树管理/获取虚拟服务树列表

=cut

get '/vtree/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id treeid name );
    my $x = eval{ $api::mysql->query( sprintf( "select %s from `openc3_connector_vtree` where treeid='$param->{projectid}'", join( ',', @col ) ), \@col ) };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $x };
};

=pod

虚拟服务树/服务树管理/创建虚拟服务树节点

=cut

post '/vtree/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name      => qr/^[a-zA-Z][a-zA-Z0-9_\-]*[a-zA-Z0-9]$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','CREATE VTREE','PROJECTID:$param->{projectid} NAME:$param->{name}')" ); };
 
    eval{ $api::mysql->execute( "insert into openc3_connector_vtree (`treeid`,`name`) values('$param->{projectid}', '$param->{name}')" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, info => 'ok' };
};

=pod

虚拟服务树/服务树管理/删除虚拟服务树节点

=cut

del '/vtree/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id        => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','DELETE VTREE','PROJECTID:$param->{projectid} ID:$param->{id}')" ); };

    eval{ $api::mysql->execute( "delete from openc3_connector_vtree where id='$param->{id}' and treeid='$param->{projectid}'" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
