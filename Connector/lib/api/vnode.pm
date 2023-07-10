package api::vnode;
use Dancer ':syntax';
use Dancer qw(cookie);
use JSON qw();
use POSIX;
use api;
use uuid;
use Format;

=pod

虚拟服务树/服务树主机管理/获取主机列表

=cut

get '/vnode/:vtreeid' => sub {
    my $param = params();
    my $error = Format->new( 
        vtreeid => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $tree = eval{ $api::mysql->query( sprintf( "select treeid from `openc3_connector_vtree` where id='$param->{vtreeid}'" ) ) };
    return +{ stat => $JSON::false, info => $@ } if $@;

    return +{ stat => $JSON::false, info => "nofind treeid by vtreeid" } unless $tree && @$tree > 0;
    my $treeid = $tree->[0][0];

    my $pmscheck = api::pmscheck( 'openc3_connector_read', $treeid ); return $pmscheck if $pmscheck;

    my @col = qw( id name );
    my $x = eval{ $api::mysql->query( sprintf( "select %s from `openc3_connector_vnode` where vtreeid='$param->{vtreeid}'", join( ',', @col ) ), \@col ) };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my %name; map{ $name{$_->{name}} = 1;}@$x;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \%name };
};

=pod

虚拟服务树/服务树主机管理/添加主机

=cut

post '/vnode/:vtreeid' => sub {
    my $param = params();
    my $error = Format->new( 
        name      => qr/^[a-zA-Z0-9][a-zA-Z0-9_\-\.,]*[a-zA-Z0-9]$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $tree = eval{ $api::mysql->query( sprintf( "select treeid from `openc3_connector_vtree` where id='$param->{vtreeid}'" ) ) };
    return +{ stat => $JSON::false, info => $@ } if $@;

    return +{ stat => $JSON::false, info => "nofind treeid by vtreeid" } unless $tree && @$tree > 0;
    my $treeid = $tree->[0][0];

    my $pmscheck = api::pmscheck( 'openc3_connector_write', $treeid ); return $pmscheck if $pmscheck;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','ADD VNODE','PROJECTID:$param->{projectid} NAME:$param->{name}')" ); };
 
    eval{ map{ $api::mysql->execute( "insert into openc3_connector_vnode (`name`,`vtreeid`) values('$_','$param->{vtreeid}')" ); } grep{ /^[a-zA-Z0-9]/ }split /,/, $param->{name} };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, info => 'ok' };
};

=pod

虚拟服务树/服务树主机管理/删除主机

=cut

del '/vnode/:vtreeid' => sub {
    my $param = params();
    my $error = Format->new( 
        name      => qr/^[a-zA-Z0-9][a-zA-Z0-9_\-\.,]*[a-zA-Z0-9]$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;

    my $tree = eval{ $api::mysql->query( sprintf( "select treeid from `openc3_connector_vtree` where id='$param->{vtreeid}'" ) ) };
    return +{ stat => $JSON::false, info => $@ } if $@;

    return +{ stat => $JSON::false, info => "nofind treeid by vtreeid" } unless $tree && @$tree > 0;
    my $treeid = $tree->[0][0];

    my $pmscheck = api::pmscheck( 'openc3_connector_write', $treeid ); return $pmscheck if $pmscheck;

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','DEL VNODE','PROJECTID:$param->{projectid} NAME:$param->{name}')" ); };

    eval{ map{ $api::mysql->execute( "delete from openc3_connector_vnode where vtreeid='$param->{vtreeid}' and name='$_'" ); } grep{ /^[a-zA-Z0-9]/ }split /,/, $param->{name} };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, info => 'ok' };
};

true;
