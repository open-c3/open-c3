package api::monitor::config::collector;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

=pod

监控系统/采集配置/获取列表

=cut

get '/monitor/config/collector/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( id type subtype content1 content2 edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_collector
                where projectid='$projectid'", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

监控系统/采集配置/获取单个采集配置详情

=cut

get '/monitor/config/collector/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( id type subtype content1 content2 edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_collector where projectid='$projectid' and id='$param->{id}'", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0] };
};

=pod

监控系统/采集配置/添加或编辑采集配置

=cut

post '/monitor/config/collector/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 0,
        type => qr/^[a-zA-Z0-9]+$/, 1,
        subtype => qr/^[a-zA-Z0-9]+$/, 1,
        content1 => [ 'mismatch', qr/'/ ], 1,
        content2 => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    return  +{ stat => $JSON::false, info => "process need in: ^[a-zA-Z0-9: \.\-_@]+\$" }
        if $param->{type} eq "process" && ! ( $param->{content1} =~ /^[a-zA-Z0-9: \.\-_@]+$/ || $param->{content1} =~ /^[a-zA-Z0-9: \.\-_@]+;[a-zA-Z0-9][a-zA-Z0-9\.\-_]+$/ );
    return  +{ stat => $JSON::false, info => "port need in: number" }
        if $param->{type} eq "port" && ! ( $param->{content1} =~ /^\d+[,\d+]+$/ || $param->{content1} =~ /^\d+;[a-zA-Z0-9][a-zA-Z0-9\.\-_]+$/ );

    return  +{ stat => $JSON::false, info => "http url need in: ^[;a-zA-Z0-9 \.\-_@\:\/\?&=]+\$" } if $param->{type} eq "http" && $param->{content1} !~ /^[;a-zA-Z0-9 \.\-_@\:\/\?&=]+$/;
    return  +{ stat => $JSON::false, info => "http check need in: ^[a-zA-Z0-9 \.\-_@]*\$"        } if $param->{type} eq "http" && $param->{content2} !~ /^[a-zA-Z0-9 \.\-_@]*$/;

    return  +{ stat => $JSON::false, info => "path need in: ^/[\/a-zA-Z0-9\.\-_]+\$"       } if $param->{type} eq "path" && $param->{content1} !~ /^\/[\/a-zA-Z0-9\.\-_]+$/;
    return  +{ stat => $JSON::false, info => "path check need in: ^[\/a-zA-Z0-9 \.\-_]*\$" } if $param->{type} eq "path" && $param->{content2} !~ /^[\/a-zA-Z0-9 \.\-_]*$/;

    my $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my ( $id, $projectid, $type, $subtype, $content1, $content2 ) = @$param{qw( id projectid type subtype content1 content2 )};
    $content2 = '' unless defined $content2;

    eval{
        my $title = $id ? "UPDATE" : "ADD";
        $api::auditlog->run( user => $user, title => "$title MONITOR CONFIG COLLECTOR", content => "TREEID:$projectid TYPE:$type SUBTYPE:$subtype CONTENT1:$content1 CONTENT2:$content2" );
        if( $param->{id} )
        {
            $api::mysql->execute( "update openc3_monitor_config_collector set type='$type',subtype='$subtype',content1='$content1',content2='$content2',edit_user='$user' where projectid='$projectid' and id='$id'" );
        }
        else
        {
            $api::mysql->execute( "insert into openc3_monitor_config_collector (`projectid`,`type`,`subtype`,`content1`,`content2`,`edit_user`)
                values('$projectid','$type','$subtype','$content1','$content2','$user')" );
        }
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

监控系统/采集配置/删除采集配置

=cut

del '/monitor/config/collector/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $cont = eval{ $api::mysql->query( "select type,subtype,content1,content2 from openc3_monitor_config_collector where id='$param->{id}'")};
    my $c = $cont->[0];
    eval{ $api::auditlog->run( user => $user, title => 'DEL MONITOR CONFIG COLLECTOR', content => "TREEID:$param->{projectid} TYPE:$c->[0] SUBTYPE:$c->[1] CONTENT1:$c->[2] CONTENT2:$c->[3]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "delete from openc3_monitor_config_collector where id='$param->{id}' and projectid='$param->{projectid}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
