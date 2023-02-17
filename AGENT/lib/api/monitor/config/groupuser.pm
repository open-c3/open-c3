package api::monitor::config::groupuser;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

=pod

监控系统/告警组/获取组内成员

=cut

get '/monitor/config/groupuser/:groupid' => sub {
    my $param = params();
    my $error = Format->new( 
        groupid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;

    my @col = qw( id user edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_groupuser where groupid='$param->{groupid}'", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

监控系统/告警组/添加成员

=cut

post '/monitor/config/groupuser' => sub {
    my $param = params();
    my $error = Format->new( 
        groupid => qr/^\d+$/, 0,
        user => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $auth = eval{ $api::mysql->query( "select share from openc3_monitor_config_group where id='$param->{groupid}'" ) };
    return +{ stat => $JSON::false, info => $@ } if $@;
    my %share = map{ $_ => 1 } split /,/, @$auth ? $auth->[0][0] : '';
    unless( $share{$user} )
    {
        my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;
    }

    my ( $groupid, $usr ) = @$param{qw( groupid user )};

    eval{
        $api::auditlog->run( user => $user, title => "ADD MONITOR CONFIG GROUPUSER", content => "GROUPID:$groupid USER:$usr" );
        $api::mysql->execute( "insert into openc3_monitor_config_groupuser (`groupid`,`user`,`edit_user`) values('$groupid','$usr','$user')" );
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

监控系统/告警组/删除成员

=cut

del '/monitor/config/groupuser/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $auth = eval{ $api::mysql->query( "select share from openc3_monitor_config_group where id in ( select groupid from openc3_monitor_config_groupuser where id='$param->{id}' )" ) };
    return +{ stat => $JSON::false, info => $@ } if $@;
    my %share = map{ $_ => 1 } split /,/, @$auth ? $auth->[0][0] : '';
    unless( $share{$user} )
    {
        my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;
    }

    my $cont = eval{ $api::mysql->query( "select `user`,`groupid` from openc3_monitor_config_groupuser where id='$param->{id}'")};
    my $c = $cont->[0];
    eval{ $api::auditlog->run( user => $user, title => 'DEL MONITOR CONFIG GROUPUSER', content => "NAME:$c->[0] GROUPID:$c->[1]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "delete from openc3_monitor_config_groupuser where id='$param->{id}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
