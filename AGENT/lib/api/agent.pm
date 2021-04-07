package api::agent;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;

get '/agent/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( id status version edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from agent
                where projectid='$projectid'", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

get '/agent/:projectid/:regionid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        regionid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( id ip status version edit_time fail reason );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from agent
                where relationid in ( select id from project_region_relation where projectid='$projectid' and regionid='$param->{regionid}')", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

post '/agent/:projectid/:regionid/subnet' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        regionid => qr/^\d+$/, 1,
        subnet => qr/^[\d\.\/, ]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @subnet = grep{ $_ =~ /^\d+\.\d+\.\d+\.\d+\/\d+$/ } split /,| /, $param->{subnet};

    return +{ stat => $JSON::false, info => 'No effective subnet' } unless @subnet;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'ADD SUBNET', content => "TREEID:$param->{projectid} REGIONID:$param->{regionid} SUBNET:$param->{subnet}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{
        map{
            $api::mysql->execute( "replace into agent (`relationid`,`projectid`,`ip`,`status`,`reason`,`version`) 
            select id,'$param->{projectid}', '$_','success', 'subnet', '0' from project_region_relation where regionid='$param->{regionid}' and projectid='$param->{projectid}'" );
        }@subnet;
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};


del '/agent/:projectid/:agentid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        agentid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $agentip = eval{ $api::mysql->query( "select ip from agent where id='$param->{agentid}'")};
    eval{ $api::auditlog->run( user => $user, title => 'DEL SUBNET', content => "TREEID:$param->{projectid} SUBNET:$agentip->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "delete from agent where id='$param->{agentid}' and projectid='$param->{projectid}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
