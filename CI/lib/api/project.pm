package api::project;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

=pod

K8S/流水线/获取K8S集群关联的流水线

在K8S管理页面中，显示应用在哪些流水线中被使用了。

=cut

get '/project/kubernetes/:ticketid' => sub {
    my $param = params();
    my $error = Format->new( ticketid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my @col = qw( id groupid name ci_type_kind ci_type_namespace ci_type_name );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_project where ci_type='kubernetes' and  ci_type_ticketid='$param->{ticketid}' and groupid<>'0'", join( ',', @col)), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;

    my %r;
    for my $row ( @$r )
    {
        my @name = split /,/, $row->{ci_type_name};
        for my $name ( @name )
        {
            $r{$row->{ci_type_kind}}{$row->{ci_type_namespace}}{$name} ||= [] ;
            push @{$r{$row->{ci_type_kind}}{$row->{ci_type_namespace}}{$name}}, +{ %$row, name => @name > 1 ? "$row->{name}(Multiple)" : $row->{name} };
        }
    }

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \%r };
};

=pod

流水线/获取单个流水线CI配置详情

=cut

get '/project/:groupid/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $relation = $param->{relation} ? ", '0'" : '';
    my @col = qw( id status autobuild name excuteflow calljobx calljob
        webhook webhook_password webhook_release rely buildimage buildscripts buildcachepath
        follow_up follow_up_ticketid callback groupid addr notify
        edit_user edit_time  slave last_findtags last_findtags_success 
        ticketid tag_regex autofindtags callonlineenv calltestenv findtags_at_once
        ci_type ci_type_ticketid ci_type_kind ci_type_namespace ci_type_name ci_type_container ci_type_repository ci_type_dockerfile ci_type_dockerfile_content
        ci_type_open ci_type_concurrent ci_type_approver1 ci_type_approver2
        audit_level
        cpulimit memlimit
        saveasdir gitclonebycache
        nomail nomesg
        notifyci notifycd
        );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_project where id='$projectid'", join( ',', @col)), \@col )};

    my $data = $r && @$r ? $r->[0] : +{};

    map{ 
        $data->{$_}  = decode_base64( $data->{$_}  ) if defined $data->{$_}
    }qw( buildscripts webhook_password password ci_type_dockerfile_content );

    map{
        $data->{$_}  = Encode::decode("utf8", $data->{$_}) if defined $data->{$_}
    }qw( buildscripts ci_type_dockerfile_content );

    $data->{tag_regex} = '' if $data->{tag_regex} eq '_NULL_';

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $data  };
};

=pod

流水线/编辑CI配置

=cut

post '/project/:groupid/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        status => qr/^\d+$/, 1,
        audit_level => qr/^\d+$/, 1,
        autobuild => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 0,
        excuteflow => [ 'mismatch', qr/'/ ], 0,
        calljobx => [ 'mismatch', qr/'/ ], 0,
        calljob => [ 'mismatch', qr/'/ ], 0,
        webhook => qr/^\d+$/, 1,
        webhook_password => [ 'mismatch', qr/'/ ], 0,
        webhook_release => [ 'mismatch', qr/'/ ], 0,
        rely => qr/^\d+$/, 1,
        buildimage => [ 'mismatch', qr/'/ ], 0,
        buildcachepath => qr/^[a-zA-Z0-9_\-\.]*$/, 0,
        follow_up => [ 'mismatch', qr/'/ ], 0,
        follow_ucallback => [ 'mismatch', qr/'/ ], 0,
        groupid => qr/^\d+$/, 1,
        addr => [ 'mismatch', qr/'/ ], 1,
        username => [ 'mismatch', qr/'/ ], 0,
        password => [ 'mismatch', qr/'/ ], 0,
        notify => [ 'mismatch', qr/'/ ], 0,
        notifyci => [ 'mismatch', qr/'/ ], 0,
        notifycd => [ 'mismatch', qr/'/ ], 0,
        tag_regex => [ 'mismatch', qr/'/ ], 0,
        autofindtags => qr/^\d+$/, 1,
        callonlineenv => qr/^\d+$/, 1,
        calltestenv => qr/^\d+$/, 1,
        ticketid => qr/^\d*$/, 0,
        follow_up_ticketid => qr/^\d*$/, 0,

        cpulimit => qr/^\d*\.?\d*$/, 1,
        memlimit => qr/^\d*$/, 1,

        saveasdir => qr/^\d*$/, 0,
        gitclonebycache => qr/^\d*$/, 0,

        nomail => qr/^\d*$/, 0,
        nomesg => qr/^\d*$/, 0,

        ci_type => [ 'in', 'default', 'kubernetes' ], 1,
        ci_type_ticketid => [ 'mismatch', qr/'/ ], 0,
        ci_type_kind => [ 'mismatch', qr/'/ ], 0,
        ci_type_namespace => [ 'mismatch', qr/'/ ], 0,
        ci_type_name => [ 'mismatch', qr/'/ ], 0,
        ci_type_container => [ 'mismatch', qr/'/ ], 0,
        ci_type_repository => [ 'mismatch', qr/'/ ], 0,
        ci_type_dockerfile => [ 'mismatch', qr/'/ ], 0,
        ci_type_dockerfile_content => [ 'mismatch', qr/'/ ], 0,
        ci_type_open => [ 'mismatch', qr/'/ ], 0,
        ci_type_concurrent => [ 'mismatch', qr/'/ ], 0,
        ci_type_approver1 => [ 'mismatch', qr/'/ ], 0,
        ci_type_approver2 => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_write', $param->{groupid} ); return $pmscheck if $pmscheck;

    $param->{tag_regex} = '_NULL_' if ( ! defined $param->{tag_regex} ) || ( $param->{tag_regex} eq "" );

    map{ 
        $param->{$_}  = encode_base64( encode('UTF-8',  $param->{$_}) );
    }qw( buildscripts webhook_password password ci_type_dockerfile_content );

    my $projectid = $param->{projectid};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'EDIT FLOWLINE CI', content => "TREEID:$param->{groupid} FLOWLINEID:$projectid NAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my @col = qw( 
        status autobuild name excuteflow calljobx calljob
        webhook webhook_password webhook_release rely buildimage buildscripts buildcachepath
        follow_up follow_up_ticketid callback groupid addr
        notify ticketid tag_regex autofindtags callonlineenv calltestenv
        ci_type ci_type_ticketid ci_type_kind ci_type_namespace ci_type_name ci_type_container ci_type_repository ci_type_dockerfile ci_type_dockerfile_content
        ci_type_open ci_type_concurrent ci_type_approver1 ci_type_approver2
        audit_level
        cpulimit memlimit
        saveasdir gitclonebycache
        nomail nomesg
        notifyci notifycd
    );
    eval{ 
        $api::mysql->execute(
            sprintf "replace into openc3_ci_project (`id`,`edit_user`,%s ) values( '$projectid','$user', %s )", 
            join(',',map{"`$_`"}@col), join(',',map{"'$param->{$_}'"}@col)
        );
    };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

流水线/删除CI配置

=cut

del '/project/:groupid/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        groupid => qr/^\d+$/, 1,
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_delete', $param->{groupid} ); return $pmscheck if $pmscheck;

    my ( $groupid, $projectid ) = @$param{qw( groupid projectid )};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ),
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $flowname = eval{ $api::mysql->query( "select name from openc3_ci_project where groupid='$groupid' and id='$projectid'" )}; 
    eval{ $api::auditlog->run( user => $user, title => 'DELETE FLOWLINE', content => "TREEID:$groupid FLOWLINEID:$projectid NAME:$flowname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( "delete from openc3_ci_rely where projectid='$projectid'" );
        $api::mysql->execute( "delete from openc3_ci_project where groupid='$groupid' and id='$projectid'" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

=pod

流水线/流水线改名

=cut

post '/project/:groupid/:projectid/rename' => sub {
    my $param = params();
    my $error = Format->new( 
        groupid => qr/^\d+$/, 1,
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_write', $param->{groupid} ); return $pmscheck if $pmscheck;


    my $projectid = $param->{projectid};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'RENAME FLOWLINE CI', content => "TREEID:$param->{groupid} FLOWLINEID:$projectid NAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{ 
        $api::mysql->execute( "update openc3_ci_project set name='$param->{name}' where id=$projectid and groupid=$param->{groupid}");
    };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

流水线/触发一次找tag操作

=cut

put '/project/:groupid/:projectid/findtags_at_once' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_control', $param->{groupid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'FIND TAGS', content => "TREEID:$param->{groupid} FLOWLINEID:$param->{projectid}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{ 
        $api::mysql->execute( "update openc3_ci_project set findtags_at_once=1 where id=$param->{projectid}" ); 
    };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
