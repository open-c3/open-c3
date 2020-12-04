package api::project_region_relation;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;

get '/project_region_relation/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id projectid regionid );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from project_region_relation
                where projectid='$param->{projectid}'", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

#regionid
post '/project_region_relation/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        regionid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $r = eval{ 

        $api::mysql->execute( "insert into log (`projectid`,`user`,`info`) select '$param->{projectid}','$user',concat('selected regionid $param->{regionid} region name ', name ) from region where id='$param->{regionid}'" );
        $api::mysql->execute( "insert into project_region_relation (`projectid`,`regionid`) values( '$param->{projectid}', '$param->{regionid}' )")};

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

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
    my $r = eval{ 

        $api::mysql->execute( "insert into log (`projectid`,`user`,`info`) select '$param->{projectid}','$user',concat('cancel regionid $param->{regionid} region name ', name ) from region where id='$param->{regionid}'" );
        $api::mysql->execute( "delete from agent where relationid in( select id from project_region_relation where regionid='$regionid' and projectid='$projectid')" );
        $api::mysql->execute( "delete from proxy where regionid in ( select id from region where id='$regionid' and projectid='$projectid')" );
        $api::mysql->execute( "delete from project_region_relation where regionid='$regionid' and projectid='$projectid'" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
