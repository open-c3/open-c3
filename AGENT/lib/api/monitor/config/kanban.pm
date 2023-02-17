package api::monitor::config::kanban;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

=pod

监控系统/获取服务树下绑定的看板

=cut

get '/monitor/config/kanban/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $where = $projectid ? " where projectid='$projectid'" : "";
    my @col = qw( id projectid name url edit_user edit_time default );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_kanban
                $where", join( ',', map{ "`$_`" }@col)), \@col )};

    my ( @r, %default );
    for my $x ( @$r )
    {
        if( $x->{name} =~ /^_(\d+)_$/ )
        {
            $default{ $1 } = $x->{default};
        }
        else
        {
            push @r, $x;
        }
    }

    my @x = `cat cat /data/Software/mydan/AGENT/lib/api/monitor/config/kanban.default`;
    chomp @x;
    
    for( @x )
    {
        my ( $id, $name, $url ) = split /;/, $_, 3;
        utf8::decode($name);
        $url =~ s/\{\{treeid\}\}/$param->{projectid}/g;
        push @r, +{
            projectid => $param->{projectid},
            id => $id,
            name => $name,
            url => $url,
            edit_user => 'sys',
            edit_time => '2022-11-05 12:16:30',
            default   => $default{ $id } || 0,
        };
    }

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@r };
};

=pod

监控系统/获取看板详情

=cut

get '/monitor/config/kanban/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( id projectid name url edit_user edit_time default );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_kanban where projectid='$projectid' and id='$param->{id}'", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0] };
};

=pod

监控系统/添加看板

=cut

post '/monitor/config/kanban/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
        url => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my ( $projectid, $name, $url ) = @$param{qw( projectid name url)};

    eval{
        $api::auditlog->run( user => $user, title => "ADD MONITOR CONFIG KANBAN", content => "TREEID:$projectid NAME:$name URL:$url" );
        $api::mysql->execute( "insert into openc3_monitor_config_kanban (`projectid`,`name`,`url`,`edit_user`)
            values('$projectid','$name','$url','$user')" );
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

监控系统/设置缺省看板

=cut

post '/monitor/config/kanban/setdefault/:projectid/:kanbanid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        kanbanid => qr/^\d+$/, 1,
        stat => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my ( $projectid, $kanbanid, $stat ) = @$param{qw( projectid kanbanid stat )};

    $stat = $stat ? 1 : 0;
    my $title = $stat ? 'SET' : 'UNSET';

    eval{
        $api::auditlog->run( user => $user, title => "$title MONITOR DEFAULT KANBAN", content => "TREEID:$projectid KANBANID:$kanbanid" );
        $api::mysql->execute( "update openc3_monitor_config_kanban set `default`=0 where projectid=$projectid" );
        if( $kanbanid > 100000000 )
        {
            $api::mysql->execute( "delete from openc3_monitor_config_kanban where projectid=$projectid and name='_${kanbanid}_'" );
            $api::mysql->execute( "insert into openc3_monitor_config_kanban (`projectid`,`name`,`url`,`edit_user`,`default`)
                values('$projectid','_${kanbanid}_','_url_','$user',$stat)" );
        }
        else
        {
            $api::mysql->execute( "update openc3_monitor_config_kanban set `default`=$stat where projectid=$projectid and id=$kanbanid" );
        }
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

监控系统/删除看板

=cut

del '/monitor/config/kanban/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $cont = eval{ $api::mysql->query( "select `name`,`url` from openc3_monitor_config_kanban where id='$param->{id}'")};
    my $c = $cont->[0];
    eval{ $api::auditlog->run( user => $user, title => 'DEL MONITOR CONFIG KANBAN', content => "TREEID:$param->{projectid} NAME:$c->[0] URL:$c->[1]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "delete from openc3_monitor_config_kanban where id='$param->{id}' and projectid='$param->{projectid}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
