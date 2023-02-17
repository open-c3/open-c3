package api::project_region_relation;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

=pod

AGENT/区域管理/获取区域和服务树的绑定关系

=cut

get '/project_region_relation/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id projectid regionid );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_agent_project_region_relation
                where projectid='$param->{projectid}'", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

AGENT/区域管理/添加区域和服务树的绑定关系

=cut

post '/project_region_relation/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        regionid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $regionname = eval{ $api::mysql->query( "select name from openc3_agent_region where id='$param->{regionid}'")};
    eval{ $api::auditlog->run( user => $user, title => 'USE REGION', content => "TREEID:$param->{projectid} REGIONID:$param->{regionid} REGIONNAME:$regionname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ $api::mysql->execute( "insert into openc3_agent_project_region_relation (`projectid`,`regionid`) values( '$param->{projectid}', '$param->{regionid}' )")};

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

AGENT/区域管理/解除区域和服务树的绑定关系

=cut

del '/project_region_relation/:projectid/:regionid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        regionid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my ( $regionid, $projectid ) = @$param{qw( regionid projectid )};

    my $regionname = eval{ $api::mysql->query( "select name from openc3_agent_region where id='$param->{regionid}'")};
    eval{ $api::auditlog->run( user => $user, title => 'OUT REGION', content => "TREEID:$param->{projectid} REGIONID:$param->{regionid} REGIONNAME:$regionname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( "delete from openc3_agent_agent where relationid in( select id from openc3_agent_project_region_relation where regionid='$regionid' and projectid='$projectid')" );
        $api::mysql->execute( "delete from openc3_agent_proxy where regionid in ( select id from openc3_agent_region where id='$regionid' and projectid='$projectid')" );
        $api::mysql->execute( "delete from openc3_agent_project_region_relation where regionid='$regionid' and projectid='$projectid'" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
