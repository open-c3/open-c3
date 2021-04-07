package api::region;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;

#relation 同时返回项目0的列表
get '/region/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $relation = $param->{relation} ? ", '0'" : '';
    my @col = qw( id name projectid create_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from region
                where projectid in ( '$projectid' $relation ) order by projectid,id", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

#name
post '/region/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'ADD REGION', content => "TREEID:$param->{projectid} NAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( "insert into region (`projectid`,`name`) values( '$projectid', '$param->{name}' )");
    };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

del '/region/:projectid/:regionid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        regionid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my ( $regionid, $projectid ) = @$param{qw( regionid projectid )};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $regionname = eval{ $api::mysql->query( "select name from region where id='$param->{regionid}'")};
    eval{ $api::auditlog->run( user => $user, title => 'DEL REGION', content => "TREEID:$param->{projectid} NAME:$regionname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( "delete from agent where relationid in( select id from project_region_relation where regionid='$regionid' and projectid='$projectid')" );
        $api::mysql->execute( "delete from proxy where regionid in ( select id from region where id='$regionid' and projectid='$projectid')" );
        $api::mysql->execute( "delete from project_region_relation where regionid='$regionid' and projectid='$projectid'" );
        $api::mysql->execute( "delete from region where id='$regionid' and projectid='$projectid'" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

#Extended

get '/region/:projectid/active' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( id name create_time );
    my $r = eval{ 
        $api::mysql->query( 
            "select region.id,region.name,region.projectid from region,project_region_relation
                where project_region_relation.regionid=region.id and project_region_relation.projectid='$param->{projectid}'", 
                [qw( id region regionprojectid )]
        )};

    return  +{ stat => $JSON::false, info => $@ } if  $@;
    my $proxy = eval{
        $api::mysql->query(
            "select regionid,count(ip),status  from proxy where regionid in
                ( select regionid from project_region_relation where projectid='$param->{projectid}' )  group by regionid, status",
            [qw( regionid ipcount status )]
        )
    };

    return  +{ stat => $JSON::false, info => $@ } if  $@;
    my $agent = eval{

        $api::mysql->query(
        "select project_region_relation.regionid,count(ip),status from agent,project_region_relation 
            where project_region_relation.id=agent.relationid and project_region_relation.projectid='$param->{projectid}' group by project_region_relation.regionid,status",
        [qw( regionid ipcount status )]
    )
    };

    return  +{ stat => $JSON::false, info => $@ } if  $@;

    my ( %proxy, %agent );
    map{ $proxy{$_->{regionid}}{$_->{status}} = $_->{ipcount} }@$proxy;
    map{ $agent{$_->{regionid}}{$_->{status}} = $_->{ipcount} }@$agent;
    map{ $_->{proxy} = $proxy{$_->{id}}; $_->{agent} = $agent{$_->{id}} }@$r;
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r};
};

true;
