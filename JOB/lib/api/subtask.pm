package api::subtask;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

get '/subtask/:projectid/:taskuuid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        taskuuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id subtask_type uuid nodecount starttime finishtime runtime status pause );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_subtask
                where parent_uuid in ( select uuid from openc3_job_task where projectid='$param->{projectid}' and uuid='$param->{taskuuid}') order by id asc",
                    join ',',@col ), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;

    my %extended;

    map{ push @{$extended{$_->{subtask_type}}}, $_->{uuid} }@$r;

    my %e;
    my %col = (
        cmd => [ qw( id uuid name user timeout pause node_type node_cont scripts_type scripts_cont deployenv action batches ) ],
        scp => [ qw( id uuid name user timeout pause src_type src sp dst_type dst dp chown chmod deployenv action batches ) ],
        approval => [ qw( id uuid name cont approver deployenv action batches everyone ) ],
    );
    for my $type ( qw( cmd scp approval ) )
    {
        next unless $extended{$type};
        my $col = $col{$type};
        my $t = eval{ $api::mysql->query( sprintf( "select %s from openc3_job_plugin_$type where uuid in( %s )", 
                    join( ',',@$col ), join( ',', map{"'$_'"}@{$extended{$type}}) ), $col) };
        return +{ stat => $JSON::false, info => $@ } if $@;
        map{ $_->{scripts_cont} =  Encode::decode("utf8",  decode_base64( $_->{scripts_cont} )) if $_->{scripts_cont} !~ /^\d+$/; }@$t if $type eq 'cmd';
        map{ $e{$type}{$_->{uuid}}=$_ }@$t;
    }
    return +{ stat => $JSON::true, data => [ map{ +{ %$_, extended => $e{$_->{subtask_type}} ? $e{$_->{subtask_type}}{$_->{uuid}} : +{}}}@$r ]};
};

#这里通过子任务uuid查不太严谨，正常应该通过id  活着子任务uuid＋子任务类型
get '/subtask/:projectid/:taskuuid/:subtaskuuid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        taskuuid => qr/^[a-zA-Z0-9]+$/, 1,
        subtaskuuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id subtask_type uuid nodecount starttime finishtime runtime status pause );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_subtask
                where uuid='$param->{subtaskuuid}' and parent_uuid in ( select uuid from openc3_job_task where projectid='$param->{projectid}' and uuid='$param->{taskuuid}')",
                    join ',',@col ), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::false, info => 'nofind' } unless $r && @$r;

    my $data = $r->[0];

    #TODO delete user
    my $col = [qw( id uuid name user timeout pause)];
    $col = [qw( id uuid name approver timeout pause)] if $data->{subtask_type} eq 'approval';
    my $t = eval{ $api::mysql->query( sprintf( "select %s from openc3_job_plugin_$data->{subtask_type} where uuid ='$data->{uuid}'", join( ',',@$col )), $col) };
    return +{ stat => $JSON::false, info => $@ } if $@;

    $data->{extended} = $t->[0] if $t->[0]{uuid} eq $data->{uuid};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $data };
};

#taskuuid
#taskuuid
#subtaskuuid
#subtasktype
#control = next,fail,running,ignore
post '/subtask/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        taskuuid => qr/^[a-zA-Z0-9]+$/, 1,
        subtaskuuid => qr/^[a-zA-Z0-9]+$/, 1,
        subtasktype => qr/^[a-zA-Z0-9]+$/, 1,
        control => [ 'in', 'next', 'fail', 'running', 'ignore' ], 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my ( $projectid, $taskuuid, $subtaskuuid, $subtasktype, $control ) 
        = @$param{qw( projectid taskuuid subtaskuuid subtasktype control )};

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    eval{ $api::auditlog->run( user => $user, title => 'JOB SUBTASK CONTROL', content => "TREEID:$param->{projectid} TASKUUID:$param->{taskuuid} SUBTASKUUID:$param->{subtaskuuid} CONTROL:$param->{control}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $sql;
    if( $control eq 'next' )
    {
        $sql = "update openc3_job_subtask set pause='' where parent_uuid='$taskuuid' and uuid='$subtaskuuid' and subtask_type='$subtasktype' 
                and pause<>'' and parent_uuid in ( select uuid from openc3_job_task where projectid='$projectid' )";
    }
    else
    {
        $sql = "update openc3_job_subtask set status='$control' where parent_uuid='$taskuuid' and uuid='$subtaskuuid' and subtask_type='$subtasktype' 
                and status='decision' and parent_uuid in ( select uuid from openc3_job_task where projectid='$projectid' )";
    }

    my $r = eval{ $api::mysql->execute( $sql ) };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $x = $@ ? $@ : $r > 0 ? undef : "no update anything:$r" ;

    if( $param->{control} eq 'fail' )
    {
        eval{ $api::mysql->execute( "update openc3_job_task set reason='stop by $user' where uuid='$taskuuid' and reason is null" ) };
    }

    return $x ?  +{ stat => $JSON::false, info => $x } : +{ stat => $JSON::true, data => $r };
};

#同上，区别是只能操作next
put '/subtask/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        taskuuid => qr/^[a-zA-Z0-9]+$/, 1,
        subtaskuuid => qr/^[a-zA-Z0-9]+$/, 1,
        subtasktype => qr/^[a-zA-Z0-9]+$/, 1,
        control => [ 'in', 'next', 'running' ], 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_control', $param->{projectid} ); return $pmscheck if $pmscheck;

    my ( $projectid, $taskuuid, $subtaskuuid, $subtasktype, $control ) 
        = @$param{qw( projectid taskuuid subtaskuuid subtasktype control )};

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    eval{ $api::auditlog->run( user => $user, title => 'JOB SUBTASK CONTROL', content => "TREEID:$param->{projectid} TASKUUID:$param->{taskuuid} SUBTASKUUID:$param->{subtaskuuid} CONTROL:$param->{control}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $sql;
    if( $control eq 'next' )
    {
        $sql = "update openc3_job_subtask set pause='' where parent_uuid='$taskuuid' and uuid='$subtaskuuid' and subtask_type='$subtasktype' 
                and pause<>'' and parent_uuid in ( select uuid from openc3_job_task where projectid='$projectid' )";
    }
    else
    {
        $sql = "update openc3_job_subtask set status='$control' where parent_uuid='$taskuuid' and uuid='$subtaskuuid' and subtask_type='$subtasktype' 
                and status='decision' and parent_uuid in ( select uuid from openc3_job_task where projectid='$projectid' )";
    }

    my $r = eval{ $api::mysql->execute( $sql ) };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $x = $@ ? $@ : $r > 0 ? undef : "no update anything:$r" ;

    if( $param->{control} eq 'fail' )
    {
        eval{ $api::mysql->execute( "update openc3_job_task set reason='stop by $user' where uuid='$taskuuid' and reason is null" ) };
    }

    return $x ?  +{ stat => $JSON::false, info => $x } : +{ stat => $JSON::true, data => $r };
};


true;
