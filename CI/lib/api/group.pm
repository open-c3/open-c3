package api::group;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

=pod

流水线/获取某个服务树下流水线列表

=cut

get '/group/:groupid' => sub {
    my $param = params();
    my $error = Format->new( groupid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid} ); return $pmscheck if $pmscheck;

    my $groupid = $param->{groupid};

    my @col = qw( id status autobuild name excuteflow calljobx calljob
        webhook webhook_password webhook_release rely buildimage buildscripts
        follow_up follow_up_ticketid callback groupid addr notify
        edit_user edit_time  slave last_findtags last_findtags_success 
        ticketid tag_regex autofindtags callonlineenv calltestenv findtags_at_once
        ci_type ci_type_ticketid ci_type_kind ci_type_namespace ci_type_name ci_type_container ci_type_dockerfile ci_type_repository
        audit_level
        );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_project where groupid='$groupid'", join( ',', @col)), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;

    my %v;
    if( @$r )
    {
        my @c = qw( id projectid uuid name user slave status starttimems finishtimems 
            starttime  finishtime calltype pid runtime reason create_time 
        );
        my $v = eval{  $api::mysql->query( sprintf( "select %s from openc3_ci_version where projectid in (%s) order by create_time", join( ',',@c), join( ',', map{$_->{id}}@$r )), \@c); };
        return +{ stat => $JSON::false, info => $@ } if $@;
        map{ $v{$_->{projectid}} = $_ }@$v;
    }

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $f = eval{  $api::mysql->query( "select ciid,name from openc3_ci_favorites where user='$user'" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my ( %favorites, %alias );
    map{ $favorites{$_->[0]} = 1; $alias{$_->[0]} = $_->[1]; }@$f;
    map{
        $_->{favorites} = $favorites{$_->{id}} || 0; $_->{alias} = $alias{$_->{id}} || '';
        $_->{lastbuild} = $v{$_->{id}} || +{};
    }@$r;

    return +{ stat => $JSON::true, data => $r };
};

=pod

流水线/获取某个服务树下收藏的流水线

=cut

get '/group/favorites/:groupid' => sub {
    my $param = params();
    my $error = Format->new( groupid => qr/^\d+$/, 1 )->check( %$param );

    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid} ); return $pmscheck if $pmscheck;

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $groupid = $param->{groupid};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my @col = qw( id status autobuild name excuteflow calljobx calljob
        webhook webhook_password webhook_release rely buildimage buildscripts
        follow_up follow_up_ticketid callback groupid addr notify
        edit_user edit_time  slave last_findtags last_findtags_success 
        ticketid tag_regex autofindtags callonlineenv calltestenv findtags_at_once );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_project where id in( select ciid from openc3_ci_favorites where user='$user')", join( ',', @col)), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;


    my $f = eval{  $api::mysql->query( "select ciid,name from openc3_ci_favorites where user='$user'" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my ( %favorites, %alias );
    map{ $favorites{$_->[0]} = 1; $alias{$_->[0]} = $_->[1]; }@$f;
    map{ $_->{favorites} = $favorites{$_->{id}} || 0; $_->{alias} = $alias{$_->{id}} || '';  }@$r;

    my $ua = LWP::UserAgent->new;
    my $res = $ua->get( "http://api.connector.open-c3.org/connectorx/usertree/treemap?cookie=". cookie( $api::cookiekey )  );
    return +{ stat => $JSON::false, info => 'get treemap from connector.pms fail' } unless $res->is_success;

    my $v = eval{JSON::decode_json $res->decoded_content};
    return +{ stat => $JSON::false, info => 'get treemap from connector.pms fail' } unless $v && ref $v eq 'HASH' && $v->{stat};
    my $treename = $v->{data} || +{};

    my %v;
    if( @$r )
    {
        my @c = qw( id projectid uuid name user slave status starttimems finishtimems 
            starttime  finishtime calltype pid runtime reason create_time 
        );
        my $v = eval{  $api::mysql->query( sprintf( "select %s from openc3_ci_version where projectid in (%s) order by create_time", join( ',',@c), join( ',', map{$_->{id}}@$r )), \@c); };
        return +{ stat => $JSON::false, info => $@ } if $@;
        map{ $v{$_->{projectid}} = $_ }@$v;
    }

    map{ $_->{lastbuild} = $v{$_->{id}} || +{}; }@$r;


    my @list; map{ push( @list, $_ ) if $_->{treename} = $treename->{$_->{groupid}}; }@$r;


    return +{ stat => $JSON::true, data => \@list };
};

=pod

流水线/获取用户所有可见的流水线

=cut

get '/group/all/:groupid' => sub {
    my $param = params();
    my $error = Format->new( groupid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid} ); return $pmscheck if $pmscheck;

    my $groupid = $param->{groupid};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my @col = qw( id status autobuild name excuteflow calljobx calljob
        webhook webhook_password webhook_release rely buildimage buildscripts
        follow_up follow_up_ticketid callback groupid addr notify
        edit_user edit_time  slave last_findtags last_findtags_success 
        ticketid tag_regex autofindtags callonlineenv calltestenv findtags_at_once audit_level );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_project", join( ',', @col)), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;


    my $f = eval{  $api::mysql->query( "select ciid,name from openc3_ci_favorites where user='$user'" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my ( %favorites, %alias );
    map{ $favorites{$_->[0]} = 1; $alias{$_->[0]} = $_->[1]; }@$f;
    map{ $_->{favorites} = $favorites{$_->{id}} || 0; $_->{alias} = $alias{$_->{id}} || '';  }@$r;

    my $ua = LWP::UserAgent->new;
    my $res = $ua->get( "http://api.connector.open-c3.org/connectorx/usertree/treemap?cookie=". cookie( $api::cookiekey )  );
    return +{ stat => $JSON::false, info => 'get treemap from connector.pms fail' } unless $res->is_success;

    my $v = eval{JSON::decode_json $res->decoded_content};
    return +{ stat => $JSON::false, info => 'get treemap from connector.pms fail' } unless $v && ref $v eq 'HASH' && $v->{stat};
    my $treename = $v->{data} || +{};

    my @list;
    map{
        push( @list, $_ ) if $_->{treename} = $treename->{$_->{groupid}};
    }@$r;
    return +{ stat => $JSON::true, data => \@list };
};

=pod

流水线/创建流水线

=cut

post '/group/:groupid' => sub {
    my $param = params();
    my $error = Format->new( 
        groupid => qr/^\d+$/, 1,
        sourceid => qr/^\d+$/, 0,
        status => qr/^\d+$/, 0,
        name => [ 'mismatch', qr/'/ ], 1,
        ci_type => [ 'mismatch', qr/'/ ], 0,
        ci_type_ticketid => [ 'mismatch', qr/'/ ], 0,
        ci_type_kind => [ 'mismatch', qr/'/ ], 0,
        ci_type_namespace => [ 'mismatch', qr/'/ ], 0,
        ci_type_name => [ 'mismatch', qr/'/ ], 0,
        ci_type_container => [ 'mismatch', qr/'/ ], 0,
        ci_type_repository => [ 'mismatch', qr/'/ ], 0,
        ci_type_dockerfile => [ 'mismatch', qr/'/ ], 0,
        ci_type_dockerfile_content => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    if( $param->{groupid} )
    {
        my $pmscheck = api::pmscheck( 'openc3_ci_write', $param->{groupid} ); return $pmscheck if $pmscheck;
    }

    my $groupid = $param->{groupid};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $r = eval{ $api::mysql->query( "select id from openc3_ci_project where groupid='$groupid' and name='$param->{name}'" )};
    return  +{ stat => $JSON::false, info => 'The name already exists' } if $r && @$r > 0;

    eval{ 
        if( defined $param->{sourceid} )
        {
            my $status = $param->{status} ? 1 : 0;
            my @t1 = qw( autobuild excuteflow calljobx calljob webhook webhook_password webhook_release rely buildimage buildscripts 
                  follow_up follow_up_ticketid callback addr notify  edit_time  slave last_findtags last_findtags_success ticketid tag_regex autofindtags callonlineenv calltestenv findtags_at_once);

            my @t2 = qw( ci_type ci_type_ticketid ci_type_kind ci_type_namespace ci_type_name ci_type_container ci_type_repository ci_type_dockerfile ci_type_dockerfile_content );

            my ( $x1, $x2 )= join ',', map{"`$_`"}@t1, @t2;

            if( $param->{ci_type} )
            {
                $x2 = join ',', (map{"`$_`"}@t1),( map{ "'$_'" }map{ $param->{$_}//'' }@t2);
            }
            else { $x2 = $x1; }

            $api::mysql->execute( "insert into openc3_ci_project (`edit_user`,`name`, `groupid`, `status`,$x1 ) select '$user','$param->{name}','$groupid',$status, $x2 from openc3_ci_project where id=$param->{sourceid}");
            my $id = $api::mysql->query( "select id from openc3_ci_project where groupid='$groupid' and name='$param->{name}'" );
            $api::mysql->execute( "insert into openc3_ci_rely (`projectid`,`path`,`addr`,`ticketid`,`tags`,`edit_user`) select '$id->[0][0]',path,addr,ticketid,tags,'$user' from openc3_ci_rely where projectid='$param->{sourceid}'" );
        }
        else
        {
            $api::mysql->execute( "insert into openc3_ci_project (`edit_user`,`name`, `groupid`, `ci_type` ) values( '$user', '$param->{name}', $groupid, 'default' )");
        }
    };

    return  +{ stat => $JSON::false, info => $@ } if $@;
    my $flowid = eval{ $api::mysql->query( "select id from openc3_ci_project where groupid='$groupid' and name='$param->{name}'" )};
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{ $api::auditlog->run( user => $user, title => 'CREATE FLOWLINE', content => "TREEID:$groupid FLOWLINEID:$flowid->[0][0] NAME:$param->{name}" ); };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, id => $flowid->[0][0] };
};

=pod

流水线/K8S集群和流水线关联

在K8S应用列表中可以直接把应用关联到某个发布流水线中。

=cut

post '/group/connectk8s/:groupid/:flowid' => sub {
    my $param = params();
    my $error = Format->new( 
        groupid => qr/^\d+$/, 1,
        flowid => qr/^\d+$/, 0,
        ci_type => [ 'mismatch', qr/'/ ], 0,
        ci_type_ticketid => [ 'mismatch', qr/'/ ], 0,
        ci_type_kind => [ 'mismatch', qr/'/ ], 0,
        ci_type_namespace => [ 'mismatch', qr/'/ ], 0,
        ci_type_name => [ 'mismatch', qr/'/ ], 0,
        ci_type_container => [ 'mismatch', qr/'/ ], 0,
        ci_type_repository => [ 'mismatch', qr/'/ ], 0,
        ci_type_dockerfile => [ 'mismatch', qr/'/ ], 0,
        ci_type_dockerfile_content => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_write', $param->{groupid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ));
    eval{ $api::auditlog->run( user => $user, title => 'CONNECTK8S', content => "GROUPID:$param->{groupid} FLOWID:$param->{flowid}" ); };

    eval{ 
        my @col = qw( ci_type ci_type_ticketid ci_type_kind ci_type_namespace ci_type_name ci_type_container ci_type_repository ci_type_dockerfile ci_type_dockerfile_content );
        $api::mysql->execute( sprintf "update openc3_ci_project set %s where id='$param->{flowid}' and groupid='$param->{groupid}'", join ',', map{ "$_='$param->{$_}'" }@col);
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};


true;
