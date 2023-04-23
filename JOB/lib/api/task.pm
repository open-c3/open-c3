package api::task;
use Dancer ':syntax';
use Dancer qw(cookie);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use uuid;
use keepalive;
use Encode qw(decode encode);
use Format;
use YAML::XS;
use BPM::Task::Config;

my $task_statistics; BEGIN { $task_statistics = Code->new( 'task_statistics' ); };

=pod

作业任务/获取任务列表

=cut

get '/task/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 0,
        user => [ 'mismatch', qr/'/ ], 0,
        status => qr/^[a-zA-Z0-9]+$/, 0,
        taskuuid => qr/^[a-zA-Z0-9]+$/, 0,
        time_start => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        time_end => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        myflow => [ 'mismatch', qr/'/ ], 0, #我发起的任务
        mytask => [ 'mismatch', qr/'/ ], 0, #我的待办任务
        mylink => [ 'mismatch', qr/'/ ], 0, #我处理过的任务
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @where;
    push @where, "name like '%$param->{name}%'" if defined $param->{name};

    my $menu;
    if( defined $param->{bpmonly} )
    {
        $menu = eval{ YAML::XS::LoadFile "/data/Software/mydan/JOB/bpm/config/menu"; };
        return +{ stat => $JSON::false, info => $@ } if $@;
    }   

    if( defined $param->{bpmonly} && $param->{alias} )
    {
        my %realname = map{ $_->{alias} => $_->{name} }@$menu;
        my $realname = $realname{ $param->{alias} } // $param->{alias};

        push @where, "name='$realname'";
    }

    map{ push @where, "$_='$param->{$_}'" if defined $param->{$_}; }qw( user status taskuuid );

    push @where, "starttime>='$param->{time_start} 00:00:00'" if defined $param->{time_start};
    push @where, "starttime<='$param->{time_end} 23:59:59'" if defined $param->{time_end};

    push @where, "extid like 'BPM%'" if defined $param->{bpmonly};

    if( $param->{mylink} || $param->{mytask} || $param->{myflow} )
    {
         my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

         push @where, "extid in ( select bpmuuid from openc3_job_bpm_usr where user='$user' and curr=0 )" if $param->{mylink};
         push @where, "extid in ( select bpmuuid from openc3_job_bpm_usr where user='$user' and curr=1 )" if $param->{mytask};
         push @where, "user='$user'"                                                                      if $param->{myflow};
    }

    my @col = qw( id uuid name user slave status starttime finishtime calltype jobtype jobuuid runtime reason variable extid );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_task
                where projectid='$projectid' %s", join( ',', @col ), @where ? ' and '.join( ' and ', @where ):'' ), \@col )};

    if( defined $param->{bpmonly} )
    {
        my @colx = qw( bpmuuid user );
        my $rx = eval{ 
            $api::mysql->query( sprintf( "select %s from openc3_job_bpm_usr where curr=1", join ',', @colx ), \@colx )};

        my %bpmuser;
        map{ $bpmuser{$_->{bpmuuid}}{$_->{user}} ++; }@$rx;
        map{ $bpmuser{ $_ } = join ',', sort keys %{ $bpmuser{$_}}; }keys %bpmuser;

        map{ $_->{handler} = $bpmuser{ $_->{extid} } // '' }@$r;

        my %menu = map{ $_->{name} => $_->{alias} // $_->{name} }@$menu;
        map{ $_->{alias} = $menu{ $_->{name} } // $_->{name} }@$r;
    }

    map{
        eval{ $_->{variable} = YAML::XS::Dump YAML::XS::Load decode("UTF-8", decode_base64( $_->{variable} ) ) } if defined $_->{variable};
        $_->{variable} = 'Error' if $@;
    }@$r;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

作业任务/获取任务数量

=cut

get '/task/:projectid/count' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $time = POSIX::strftime( "%Y-%m-00 00:00:00", localtime );
    my $r = eval{ 
        $api::mysql->query( "select status,count(*) from openc3_job_task where projectid='$param->{projectid}' and starttime>'$time' group by status" )};

    return  +{ stat => $JSON::false, info => $@ } if $@;

    my %data = map{@$_}@$r;

    map{$data{$_}||=0}qw( success running fail );
    return +{ stat => $JSON::true, data => \%data };
};

=pod

作业任务/获取任务统计信息

按时间段统计

=cut

get '/task/:projectid/total_count' => sub {
    my $param = params();
    my $error = Format->new(
      projectid => qr/^\d+$/, 1,
      time_start => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
      time_end => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $r = eval{
        $api::mysql->query( "select status,count(*) from openc3_job_task where projectid='$param->{projectid}' and starttime>='$param->{time_start} 00:00:00' and starttime<='$param->{time_end} 23:59:59' group by status" )};

    return  +{ stat => $JSON::false, info => $@ } if $@;

    my %data = map{@$_}@$r;

    map{$data{$_}||=0}qw( success running fail );
    return +{ stat => $JSON::true, data => \%data };
};

=pod

作业任务/获取任务详情

=cut

get '/task/:projectid/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id uuid name user slave status starttime finishtime calltype jobtype jobuuid runtime mutex pid starttimems finishtimems reason variable extid );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_task
                where uuid='$param->{uuid}' and projectid='$param->{projectid}'", join ',', @col ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => +{ status => 'norun' } } unless $r && @$r > 0;
    my %x = %{$r->[0]};

    eval{
        my $variable = YAML::XS::Dump YAML::XS::Load decode("UTF-8", decode_base64( $x{variable} ) );
        Encode::_utf8_on($variable);
        $x{variable} = $variable;
        } if defined $x{variable};
    $x{variable} = 'Error' if $@;

    return +{ stat => $JSON::true, data => \%x };
};

=pod

作业任务/任务重做

=cut

post '/task/:projectid/redo' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        taskuuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $slave = eval{ keepalive->new( $api::mysql )->slave() };
    return  +{ stat => $JSON::false, info => "get slave fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "system error: no slave" } unless defined $slave;

    my $x = $api::mysql->query( "select name from openc3_job_task where uuid='$param->{taskuuid}' and projectid=$param->{projectid}" );
    return  +{ stat => $JSON::false, info => "get data error from db" } unless defined $x && ref $x eq 'ARRAY';
    return  +{ stat => $JSON::false, info => "projectid, taskuuid nomatch" } unless @$x;

    my $uuid = uuid->new()->create_str;
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $calltype = $user =~ /\@app$/ ? 'api' : 'page';

    eval{ $api::auditlog->run( user => $user, title => 'TASK REDO', content => "TREEID:$param->{projectid} TASKUUID:$param->{taskuuid}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( "insert into openc3_job_task (`projectid`,`uuid`,`name`,`user`,`slave`,`status`,`calltype`,`jobtype`,`jobuuid`,`mutex`,`variable`,`extid`) 
            select projectid,'$uuid',name,'$user','$slave','init','$calltype',jobtype,jobuuid,mutex,variable,extid from openc3_job_task where uuid='$param->{taskuuid}' and projectid='$param->{projectid}'" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, uuid => $uuid, data => $r };
};

=pod

作业任务/任务权限查询

=cut

get '/task/:projectid/authorization/:group/:jobname' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobname => [ 'mismatch', qr/'/ ], 1,
        group => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $authorization = eval{ $api::mysql->query( "select id from openc3_job_variable where jobuuid in ( select uuid from openc3_job_jobs where name='$param->{jobname}' ) and name='_authorization_' and ( value='true' or value='$param->{group}' )" ); };
    return  +{ stat => $JSON::false, info => "get _authorization_ info fail: $@" } if $@;
    return  +{ stat => $JSON::false, info => "get _authorization_ error from db" } unless defined $authorization && ref $authorization eq 'ARRAY';

    return  +{ stat => $JSON::true, data => @$authorization > 0 ? 1 : 0 };
};

=pod

作业任务/提交任务

variable = { foo => 123 }

=cut

post '/task/:projectid/job' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $authorization = eval{ $api::mysql->query( "select id from openc3_job_variable where jobuuid='$param->{jobuuid}' and name='_authorization_' and value='true'" ); };
    return  +{ stat => $JSON::false, info => "get _authorization_ info fail: $@" } if $@;
    return  +{ stat => $JSON::false, info => "get _authorization_ error from db" } unless defined $authorization && ref $authorization eq 'ARRAY';

    my $point = @$authorization > 0 ? 'openc3_job_control' : 'openc3_job_write';
    my $pmscheck = api::pmscheck( $point, $param->{projectid} ); return $pmscheck if $pmscheck;

    my $slave = eval{ keepalive->new( $api::mysql )->slave() };
    return  +{ stat => $JSON::false, info => "get slave fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "system error: no slave" } unless defined $slave;

    my $x = $api::mysql->query( "select name from openc3_job_jobs where uuid='$param->{jobuuid}' and projectid=$param->{projectid}" );
    return  +{ stat => $JSON::false, info => "get data error from db" } unless defined $x && ref $x eq 'ARRAY';
    return  +{ stat => $JSON::false, info => "projectid, jobuuid nomatch" } unless @$x;

    my $name = $x->[0][0];
    my $uuid = uuid->new()->create_str;
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $calltype = $user =~ /\@app$/ ? 'api' : 'page';

    if( $param->{variable} && $param->{variable}{C3TEXT} )
    {
        my $textuuid = uuid->new()->create_str;
        my $textcont = encode_base64( encode('UTF-8', $param->{variable}{C3TEXT} ) );

        eval{ $api::mysql->execute( "insert into openc3_job_variable_text (`uuid`,`value`) values('$textuuid','$textcont')" )};
        return +{ stat => $JSON::false, info => "storage variable C3TEXT error:$@" } if $@;

        $param->{variable}{C3TEXT} = $textuuid;
    }

    my $variable = $param->{variable} ? encode_base64( encode('UTF-8', YAML::XS::Dump $param->{variable}) ) : '';

    eval{ $api::auditlog->run( user => $user, title => 'START JOB TASK', content => "TREEID:$param->{projectid} JOBUUID:$param->{jobuuid}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( "insert into openc3_job_task (`projectid`,`uuid`,`name`,`user`,`slave`,`status`,`calltype`,`jobtype`,`jobuuid`,`mutex`,`variable`) 
            values('$param->{projectid}','$uuid','$name','$user','$slave', 'init','$calltype','jobs','$param->{jobuuid}','','$variable')" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, uuid => $uuid, data => $r };
};

=pod

作业任务/监控调用作业

=cut

get '/task/:projectid/job/bymon' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobname => [ 'mismatch', qr/'/ ], 1,
        endpoint => [ 'mismatch', qr/'/ ], 1,
        tpl_id => [ 'mismatch', qr/'/ ], 1,
        exp_id => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $slave = eval{ keepalive->new( $api::mysql )->slave() };
    return  +{ stat => $JSON::false, info => "get slave fail: $@" } if $@;
    return +{ stat => $JSON::false, info => "system error: no slave" } unless defined $slave;

    my $uuid = uuid->new()->create_str;

    my $x = eval{ $api::mysql->query( "select uuid, mon_ids from openc3_job_jobs where name='$param->{jobname}' and projectid=$param->{projectid} and mon_status=1" ) };
    return  +{ stat => $JSON::false, info => "get job data error from db: $@" }  if $@;
    return  +{ stat => $JSON::false, info => "get job data error from db" } unless defined $x && ref $x eq 'ARRAY';
    return  +{ stat => $JSON::false, info => "projectid, jobname nomatch" } unless @$x;

    my $mon_ids = $x->[0][1];
    my @mon_ids = split(/,/, $mon_ids);
    unless (grep{ $_ eq $param->{tpl_id} }@mon_ids or grep{ $_ eq $param->{exp_id} }@mon_ids) {
        return  +{ stat => $JSON::false, info => "not allow this id" };
    };

    my $q = eval{ $api::mysql->query( "select count(*) from openc3_job_task where status in ('waiting', 'running') and name='$param->{jobname}'
                     and projectid=$param->{projectid} and jobtype='jobs'" ) };
    return  +{ stat => $JSON::false, info => "get task data error from db: $@" }  if $@;
    return  +{ stat => $JSON::false, info => "get task data error from db" } unless defined $q && ref $q eq 'ARRAY';
    return  +{ stat => $JSON::false, info => "this job already running" } if $q->[0][0] >= 1;

    my $jobuuid = $x->[0][0];
    my $user = 'mon@app';
    my $calltype = $user =~ /\@app$/ ? 'api' : 'page';

    my %varip;
    my @node;
    eval {
        @node = Code->new( 'nodeinfo' )->run( db => $api::mysql, ("id"=> $param->{projectid}));
        map{
                if ($_{name} eq $param->{endpoint}) {
                    %varip = ("ip" => $_{inip} );
                };
            }@node;
        if ($@) {
            %varip = ('ip'=> $param->{endpoint} );
        };
    };
    my $variable = %varip ? encode_base64( encode('UTF-8', YAML::XS::Dump %varip) ) : '';

    my $r = eval{ 
        $api::mysql->execute( "insert into openc3_job_task (`projectid`,`uuid`,`name`,`user`,`slave`,`status`,`calltype`,`jobtype`,`jobuuid`,`mutex`,`variable`) 
            values('$param->{projectid}','$uuid','$param->{jobname}','$user','$slave', 'init','$calltype','jobs','$jobuuid','','$variable')" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, uuid => $uuid, data => @node };
};

=pod

作业任务/通过作业名称调用作业

/task/:projectid/job/byname?jobname=jobname1
variable = { foo => 123 }

=cut

post '/task/:projectid/job/byname' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobname => [ 'mismatch', qr/'/ ], 1,
        uuid => qr/^[a-zA-Z0-9]{12}$/, 0,
        slave => qr/^[a-zA-Z0-9\-\.]+$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $point = ( $param->{projectid} == 0 && $param->{jobname} =~ /^bpm-/ ) ? 'openc3_job_read' : 'openc3_job_write';
    my $pmscheck = api::pmscheck( $point, $param->{projectid} ); return $pmscheck if $pmscheck;

    my $slave = eval{ $param->{slave} || keepalive->new( $api::mysql )->slave() };
    return  +{ stat => $JSON::false, info => "get slave fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "system error: no slave" } unless defined $slave;

    my $uuid;
    if( $uuid = $param->{uuid} )
    {
        my $x = eval{ $api::mysql->query( "select uuid from openc3_job_task where uuid='$uuid'" ) };
        return  +{ stat => $JSON::false, info => "get data error from db: $@" }  if $@;
        return  +{ stat => $JSON::false, info => "get data error from db" } unless defined $x && ref $x eq 'ARRAY';
        return  +{ stat => $JSON::true, info => "This task has been successfully created" } if @$x;
    }
    else
    {
        $uuid = uuid->new()->create_str;
    }

    my $x = eval{ $api::mysql->query( "select uuid from openc3_job_jobs where name='$param->{jobname}' and projectid=$param->{projectid}" ) };
    return  +{ stat => $JSON::false, info => "get data error from db: $@" }  if $@;
    return  +{ stat => $JSON::false, info => "get data error from db" } unless defined $x && ref $x eq 'ARRAY';
    return  +{ stat => $JSON::false, info => "projectid, jobname nomatch" } unless @$x;

    my $jobuuid = $x->[0][0];
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $calltype = $user =~ /\@app$/ ? 'api' : 'page';

    eval{ $api::auditlog->run( user => $user, title => 'START JOB TASK', content => "TREEID:$param->{projectid} JOBUUID:$jobuuid" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $extid = '';
    if( $param->{bpm_variable} )
    {
        my $bpmuuid = eval{ BPM::Task::Config->new()->save( $param->{bpm_variable}, $user, $param->{jobname} ); };
        return +{ stat => $JSON::false, info => $@ } if $@;
        $param->{variable} = +{ BPMUUID => $bpmuuid };
        $extid = $bpmuuid;
    }

    my $variable = $param->{variable} ? encode_base64( encode('UTF-8', YAML::XS::Dump $param->{variable}) ) : '';

    my $r = eval{ 
        $api::mysql->execute( "insert into openc3_job_task (`projectid`,`uuid`,`name`,`user`,`slave`,`status`,`calltype`,`jobtype`,`jobuuid`,`mutex`,`variable`,`extid`) 
            values('$param->{projectid}','$uuid','$param->{jobname}','$user','$slave', 'init','$calltype','jobs','$jobuuid','','$variable','$extid')" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, uuid => $uuid, data => $r };
};

=pod

作业任务/启动一个命令任务

=cut

post '/task/:projectid/plugin_cmd' => sub {
    my $param = params();

    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1, 
        user => qr/^[a-zA-Z0-9_]+$/, 1,
        node_type => [ 'in', 'builtin', 'group' ], 1,
        scripts_type => [ 'in', 'cite', 'shell', 'perl', 'python', 'php', 'buildin', 'auto' ], 1,
        timeout => qr/^\d+$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    map{ return  +{ stat => $JSON::false, info => "$_ undef" } unless defined $param->{$_} }
        qw(  node_cont scripts_type scripts_cont scripts_argv );

    if( $param->{node_type} eq 'builtin' )
    {
         $error = Format->new( 
             node_cont => qr /^[a-zA-Z0-9\.,\-]+$/, 1,
         )->check( %$param );
     
         return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    }
    else
    {
         $error = Format->new( 
             node_cont => qr /^\d+$/, 1,
         )->check( %$param );
     
         return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
         my $x = $api::mysql->query( "select id from openc3_job_nodegroup where id=$param->{node_cont} and projectid=$param->{projectid}" );
         return  +{ stat => $JSON::false, info => "get data error from db" } unless defined $x && ref $x eq 'ARRAY';
         return  +{ stat => $JSON::false, info => "nodegroup id $param->{node_cont} nofind" } unless @$x;

    }

    if( $param->{scripts_type} eq 'cite' )
    {
         $error = Format->new( 
             scripts_cont => qr /^\d+$/, 1,
         )->check( %$param );
     
         return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
         my $x = $api::mysql->query( "select id from openc3_job_scripts where id=$param->{scripts_cont} and projectid=$param->{projectid}" );
         return  +{ stat => $JSON::false, info => "get data error from db" } unless defined $x && ref $x eq 'ARRAY';
         return  +{ stat => $JSON::false, info => "scripts id $param->{scripts_cont} nofind" } unless @$x;
    }
    else
    {
         $param->{scripts_cont} = encode_base64( encode('UTF-8',$param->{scripts_cont}) );
    }

    $param->{scripts_argv} = encode_base64( encode('UTF-8', $param->{scripts_argv}) );
    $param->{timeout} ||= 60;

    my $plugin_uuid = uuid->new()->create_str;
    my @plugin_col = qw( name user node_type node_cont scripts_type scripts_cont scripts_argv timeout deployenv action batches );
    eval{ $api::mysql->execute( sprintf "insert into openc3_job_plugin_cmd (`uuid`,%s ) values('$plugin_uuid',%s)",
            join(',',map{"`$_`"}@plugin_col ), join(',',map{"'$param->{$_}'"}@plugin_col ));};
    return  +{ stat => $JSON::false, info => "insert into plugin_cmd fail" } if $@;

    my $slave = eval{ keepalive->new( $api::mysql )->slave() };
    return  +{ stat => $JSON::false, info => "get slave fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "system error: no slave" } unless defined $slave;

    my $uuid = uuid->new()->create_str;
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $calltype = $user =~ /\@app$/ ? 'api' : 'page';

    eval{ $api::auditlog->run( user => $user, title => 'START JOB CMD', content => "TREEID:$param->{projectid} TASKNAME:$param->{name} TASKUUID:$uuid" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $variable = $param->{variable} ? encode_base64( encode('UTF-8', YAML::XS::Dump $param->{variable}) ) : '';
    my $r = eval{ 
        $api::mysql->execute( "insert into openc3_job_task (`projectid`,`uuid`,`name`,`user`,`slave`,`status`,`calltype`,`jobtype`,`jobuuid`,`mutex`,`variable`) 
            values('$param->{projectid}','$uuid','$param->{name}','$user','$slave', 'init','$calltype','plugin_cmd','$plugin_uuid','','$variable')" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => +{ slave => $slave, uuid => $uuid, loguuid=> "$uuid${plugin_uuid}cmd" } };
};

=pod

作业任务/启动一个文件同步任务

=cut

post '/task/:projectid/plugin_scp' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
        user => qr/^[a-zA-Z0-9_]+$/, 1,
        src_type => [qw( in builtin group fileserver ci )], 1,
        dst_type => [qw( in builtin group fileserver )], 1,
        chown => qr/^[a-zA-Z0-9\-]+$/, 0,
        chmod => qr/^\d+$/, 0,
        timeout => qr/^\d+$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    map{ return  +{ stat => $JSON::false, info => "$_ undef" } unless defined $param->{$_} }
        qw( sp dp  );

    if( $param->{src_type} eq 'builtin' )
    {
        $error = Format->new( 
            src => qr/^[a-zA-Z0-9\.,\-]+$/, 1,
        )->check( %$param );
    
        return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    }
    elsif( $param->{src_type} eq 'group' )
    {
        $error = Format->new( 
            src => qr/^\d+$/, 1,
        )->check( %$param );
    
        return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
        my $x = $api::mysql->query( "select id from openc3_job_nodegroup where id=$param->{src} and projectid=$param->{projectid}" );
        return  +{ stat => $JSON::false, info => "get data error from db" } unless defined $x && ref $x eq 'ARRAY';
        return  +{ stat => $JSON::false, info => "nodegroup id $param->{src} nofind" } unless @$x;

    }
    elsif( $param->{src_type} eq 'ci' )
    {
        $error = Format->new( 
            src => qr/^[a-zA-Z0-9\.,\-_\$]+$/, 1,
        )->check( %$param );
    
        return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    }
    else
    {
        $param->{src} = '';
        return  +{ stat => $JSON::false, info => "sp format error" } if $param->{sp} =~ /\/|'/;
    }

    if( $param->{dst_type} eq 'builtin' )
    {
        $error = Format->new( 
            dst => qr/^[a-zA-Z0-9\.,\-]+$/, 1,
        )->check( %$param );
    
        return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    }
    elsif( $param->{dst_type} eq 'group' )
    {
        $error = Format->new( 
            dst => qr/^\d+$/, 1,
        )->check( %$param );
    
        return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
        my $x = $api::mysql->query( "select id from openc3_job_nodegroup where id=$param->{dst} and projectid=$param->{projectid}" );
        return  +{ stat => $JSON::false, info => "get data error from db" } unless defined $x && ref $x eq 'ARRAY';
        return  +{ stat => $JSON::false, info => "nodegroup id $param->{dst} nofind" } unless @$x;
    }

    $param->{timeout} ||= 60;
    $param->{scp_delete} ||= 0;
    map{ $param->{$_} = '' unless defined $param->{$_} }qw( chown chmod );

    my $plugin_uuid = uuid->new()->create_str;
    my @plugin_col = qw( name user src_type src dst_type dst sp dp chown chmod timeout scp_delete deployenv action batches );
    eval{ $api::mysql->execute( sprintf "insert into openc3_job_plugin_scp (`uuid`,%s ) values('$plugin_uuid',%s)",
            join(',',map{"`$_`"}@plugin_col ), join(',',map{"'$param->{$_}'"}@plugin_col ));};
    return  +{ stat => $JSON::false, info => "insert into plugin_scp fail" } if $@;

    my $slave = eval{ keepalive->new( $api::mysql )->slave() };
    return  +{ stat => $JSON::false, info => "get slave fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "system error: no slave" } unless defined $slave;

    my $uuid = uuid->new()->create_str;
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $calltype = $user =~ /\@app$/ ? 'api' : 'page';

    eval{ $api::auditlog->run( user => $user, title => 'START JOB SCP', content => "TREEID:$param->{projectid} TASKNAME:$param->{name} TASKUUID:$uuid" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $variable = $param->{variable} ? encode_base64( encode('UTF-8', YAML::XS::Dump $param->{variable}) ) : '';
    my $r = eval{ 
        $api::mysql->execute( "insert into openc3_job_task (`projectid`,`uuid`,`name`,`user`,`slave`,`status`,`calltype`,`jobtype`,`jobuuid`,`mutex`,`variable`) 
            values('$param->{projectid}','$uuid','$param->{name}','$user','$slave', 'init','$calltype','plugin_scp','$plugin_uuid','', '$variable')" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => +{ slave => $slave, uuid => $uuid, loguuid=> "$uuid${plugin_uuid}scp" } };
};

=pod

作业任务/启动一个审批任务

=cut

post '/task/:projectid/plugin_approval' => sub {
    my $param = params();

    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1, 
        cont => [ 'mismatch', qr/'/ ], 1, 
        approver => qr/^[a-zA-Z0-9,\@_\-\.%]+$/, 1,
        deployenv => [ 'in', 'test', 'online', 'always' ], 1,
        action => [ 'in', 'deploy', 'rollback', 'always' ], 1,
        batches => [ 'in', 'firsttime', 'thelasttime', 'notfirsttime', 'notthelasttime', 'always' ], 1,
        everyone => [ 'in', 'on', 'off' ], 1,
        timeout => qr/^\d+$/, 0,
    )->check( %$param );

    return +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    $param->{timeout} ||= 60;

    my $plugin_uuid = uuid->new()->create_str;
    my @plugin_col = qw( name cont approver deployenv action batches everyone relaxed timeout );
    eval{ $api::mysql->execute( sprintf "insert into openc3_job_plugin_approval (`uuid`,%s ) values('$plugin_uuid',%s)", join(',',map{"`$_`"}@plugin_col ), join(',',map{"'$param->{$_}'"}@plugin_col ));};
    return  +{ stat => $JSON::false, info => "insert into plugin_approval fail" } if $@;

    my $slave = eval{ keepalive->new( $api::mysql )->slave() };
    return  +{ stat => $JSON::false, info => "get slave fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "system error: no slave" } unless defined $slave;

    my $uuid = uuid->new()->create_str;
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $calltype = $user =~ /\@app$/ ? 'api' : 'page';

    eval{ $api::auditlog->run( user => $user, title => 'START JOB APPROVAL', content => "TREEID:$param->{projectid} TASKNAME:$param->{name} TASKUUID:$uuid" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $variable = $param->{variable} ? encode_base64( encode('UTF-8', YAML::XS::Dump $param->{variable}) ) : '';
    my $r = eval{ 
        $api::mysql->execute( "insert into openc3_job_task (`projectid`,`uuid`,`name`,`user`,`slave`,`status`,`calltype`,`jobtype`,`jobuuid`,`mutex`,`variable`) 
            values('$param->{projectid}','$uuid','$param->{name}','$user','$slave', 'init','$calltype','plugin_approval','$plugin_uuid','','$variable')" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => +{ slave => $slave, uuid => $uuid, loguuid=> "$uuid${plugin_uuid}approval" } };
};

=pod

作业任务/任务统计/最近几条

=cut

get '/task/:projectid/analysis/last' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        count => qr/^\d+$/, 0,
        
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    $param->{count} ||= 10;

    my @col = qw( user runtime starttime finishtime status name );
    my $r = eval{ $api::mysql->query( 
            sprintf( "select %s from openc3_job_task where projectid='$param->{projectid}' order by id desc limit $param->{count}", join ',',@col ), \@col
            )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

作业任务/任务统计/按日期

=cut

get '/task/:projectid/analysis/date' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $w = $param->{all} ? "" : "projectid='$projectid' and";

    my $time = POSIX::strftime( "%Y-%m-%d 00:00:00", localtime( time - 2592000 ) );
    my $all = eval{ $api::mysql->query( "select DATE_FORMAT(starttime, '%Y-%m-%d') as x,count(*) from openc3_job_task
            where $w starttime>'$time' group by x order by x" )};
    my $success = eval{ $api::mysql->query( "select DATE_FORMAT(starttime, '%Y-%m-%d') as x,count(*)  from openc3_job_task
            where $w status='success' and starttime>'$time' group by x order by x" )};

    my ( %all, @all ) =  map{ $_->[0] => $_->[1] }@$all;
    map{
        my $t = POSIX::strftime( "%Y-%m-%d", localtime( time - 86400 * ( 30 - $_ ) ) );
        push @all, [ $t, $all{$t} || 0 ];
    } 1 .. 30;

    my %success = map{ @$_ }@$success;
    my @data;
    map{  push @data, [ @$_, $success{$_->[0]}||0 ];}@all;
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@data };
};

=pod

作业任务/任务统计/按小时

=cut

get '/task/:projectid/analysis/hour' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $time = POSIX::strftime( "%Y-%m-%d 00:00:00", localtime( time - 2592000 ) );
    my $r = eval{ 
        $api::mysql->query( "select DATE_FORMAT(starttime, '%H'),count(*)  from openc3_job_task where projectid='$projectid' and starttime>'$time' group by DATE_FORMAT(starttime, '%H')" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

作业任务/任务统计/运行时间

=cut

get '/task/:projectid/analysis/runtime' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $time = POSIX::strftime( "%Y-%m-%d 00:00:00", localtime( time - 2592000 ) );
    my $r = eval{ 
        $api::mysql->query( "select runtime from openc3_job_task where projectid='$projectid' and starttime>'$time'" )};

    return  +{ stat => $JSON::false, info => $@ } if $@;

    my @c = qw( 0-1 1-3 3-5 5-10 10-30 );
    my $m;

    my @u;
    for( @c )
    {
        next unless $_ =~ /^(\d+)-(\d+)$/;
        push @u, [ $1 * 60, $2 * 60, $_ ];
        $m = "$2+";
    }

    $m ||= '0+';
    my %data = map{ $_ => 0 }( @c, $m );

    my $count = 0;
    for my $runtime ( map{ @$_ }@$r )
    {
        map{ 
            my $u = $_;
            if( defined $runtime && $u->[0] <= $runtime && $runtime < $u->[1] )
            { 
                $data{$u->[2]}++;
                $count++;
                next;
            }
        }@u;
        $data{$m}++;
        $count++;
    }

    map{ $data{$_} = sprintf "%0.2f", 100 * $data{$_} / $count }keys %data if $count;
    return +{ stat => $JSON::true, data => \%data };
};

=pod

作业任务/任务统计/概要

=cut

get '/task/:projectid/analysis/statistics' => sub {
    my $param = params();
    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;
    my @data = eval{ $task_statistics->run( db => $api::mysql )};
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@data };
};

true;
