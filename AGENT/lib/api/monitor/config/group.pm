package api::monitor::config::group;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

=pod

监控系统/告警组/获取列表

=cut

get '/monitor/config/group' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;

    my @col = qw( id name description edit_user edit_time share );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_group", join( ',', map{ "`$_`" }@col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

监控系统/告警组/获取详情

=cut

get '/monitor/config/group/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;

    my @col = qw( id name description edit_user edit_time share );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_group where id='$param->{id}'", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0] };
};

=pod

监控系统/告警组/创建或编辑告警组

=cut

post '/monitor/config/group' => sub {
    my $param = params();
    my $error = Format->new( 
        id           => qr/^\d+$/, 0,
        name        => [ 'mismatch', qr/'/ ], 1,
        description => [ 'mismatch', qr/'/ ], 0,
        share       => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my ( $id, $name, $description, $share ) = @$param{qw( id name description share )};

    $share ||= '';

    eval{
        my $title = $id ? "UPDATE" : "ADD";
        $api::auditlog->run( user => $user, title => "$title MONITOR CONFIG GROUP", content => "NAME:$name DESCRIPTION:$description" );
        if( $param->{id} )
        {
            $api::mysql->execute( "update openc3_monitor_config_group set `name`='$name',description='$description',share='$share' where id='$id'" );
        }
        else
        {
            $api::mysql->execute( "insert into openc3_monitor_config_group (`name`,`description`,`edit_user`,`share`) values('$name','$description','$user','$share')" );
        }
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

监控系统/告警组/删除告警组

=cut

del '/monitor/config/group/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $cont = eval{ $api::mysql->query( "select `name`,`description` from openc3_monitor_config_group where id='$param->{id}'")};
    my $c = $cont->[0];
    eval{ $api::auditlog->run( user => $user, title => 'DEL MONITOR CONFIG GROUP', content => "NAME:$c->[0] DESCRIPTION:$c->[1]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "delete from openc3_monitor_config_group where id='$param->{id}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
