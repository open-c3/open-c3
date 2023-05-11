package api::proxy;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

sub getnet
{
    my $projectid = shift;
    my $proxy = eval{
        $api::mysql->query(
            "select regionid,ip from openc3_agent_proxy where status='success' and regionid in ( select regionid from openc3_agent_project_region_relation where projectid='$projectid') order by id desc" )};

    my %proxy = map{ @$_ }@$proxy;

    my $agent = eval{ $api::mysql->query( "select openc3_agent_project_region_relation.regionid,openc3_agent_agent.ip from openc3_agent_agent,openc3_agent_project_region_relation
        where openc3_agent_project_region_relation.id=openc3_agent_agent.relationid and openc3_agent_project_region_relation.projectid='$projectid'",
        [qw( regionid ip )]
    )};

    my %data;
    for my $d ( @$agent )
    {
        next unless my $p = $proxy{$d->{regionid}};
        $data{$d->{ip}}=$p;
    }
    return \%data;
};

=pod

AGENT/代理/获取列表

=cut

get '/proxy/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my ( $projectid, @data )= $param->{projectid};

    my $inherit = eval{
        $api::mysql->query(
            "select inheritid from openc3_agent_inherit where projectid='$projectid'" )};

    return +{ stat => $JSON::false, info => $@ } if $@;

    my @id = ( $projectid );
    push( @id, split /,/, $inherit->[0][0] ) if $inherit && ref $inherit eq 'ARRAY' && @$inherit > 0;
    push @id, 0 if $projectid;

    map{ push @data, getnet( $_ ) }@id;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@data, info => "id:" . join ',', @id };
};

=pod

AGENT/代理/获取详情

=cut

get '/proxy/:projectid/:regionid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        regionid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( id status version edit_time ip fail reason );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_agent_region,openc3_agent_proxy where openc3_agent_region.id=openc3_agent_proxy.regionid and openc3_agent_region.projectid=$param->{projectid} and openc3_agent_proxy.regionid=$param->{regionid}", join(',', map{"openc3_agent_proxy.$_"}@col) ),
            \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

AGENT/代理/删除

=cut

del '/proxy/:projectid/:proxyid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        proxyid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $proxyip = eval{ $api::mysql->query( "select ip from openc3_agent_proxy where id='$param->{proxyid}'")};
    eval{ $api::auditlog->run( user => $user, title => 'DEL PROXY', content => "TREEID:$param->{projectid} REGIONID:$param->{regionid} PROXYIP:$proxyip->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "delete from openc3_agent_proxy where id='$param->{proxyid}' and regionid in (select id from openc3_agent_region where projectid='$param->{projectid}')"
        )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

AGENT/代理/添加代理

=cut

post '/proxy/:projectid/:regionid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        regionid => qr/^\d+$/, 1,
        ip => qr/^[a-zA-Z0-9 \-\._,]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @node = grep{ /^\d+\.\d+\.\d+\.\d+$/ }split /,/, $param->{ip};
    return  +{ stat => $JSON::false, info => "ip format error" } unless @node;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'ADD PROXY', content => "TREEID:$param->{projectid} REGIONID:$param->{regionid} PROXYIP:$param->{ip}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        map{
        $api::mysql->execute(
            "insert into openc3_agent_proxy(`regionid`,`ip`,`status`,`version`,`projectid`) 
                 values( '$param->{regionid}', '$_', 'success', '1.0.0', '$param->{projectid}' )" 
        )
        }@node;
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
