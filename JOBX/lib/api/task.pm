package api::task;
use Dancer ':syntax';
use Dancer qw(cookie);
use JSON;
use POSIX;
use MIME::Base64;
use api;
use uuid;
use keepalive;
use Encode qw(encode);
use Format;
use Util;
use FindBin qw( $RealBin );


#name
#user
#status
#time_start
#time_end
#taskuuid
get '/task/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d[\d,]*$/, 1,
        allowslavenull => qr/^\d$/, 0,
        name => [ 'mismatch', qr/'/ ], 0,
        user => [ 'mismatch', qr/'/ ], 0,
        status => qr/^[a-zA-Z0-9]+$/, 0,
        taskuuid => qr/^[a-zA-Z0-9]+$/, 0,
        time_start => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        time_end => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    map{
        my $pmscheck = api::pmscheck( 'openc3_jobx_read', $_ ); return $pmscheck if $pmscheck;
    }split /,/, $param->{projectid};

    my $projectid = $param->{projectid};

    my @where;
    push @where, "name like '%$param->{name}%'" if defined $param->{name};

    $param->{uuid} = $param->{taskuuid};
    map{ push @where, "$_='$param->{$_}'" if defined $param->{$_}; }qw( user status uuid );

    push @where, "starttime>='$param->{time_start} 00:00:00'" if defined $param->{time_start};
    push @where, "starttime<='$param->{time_end} 23:59:59'" if defined $param->{time_end};

    push( @where, "slave!='_null_'" ) unless $param->{allowslavenull};

    my $order = '';
    if( $param->{name} eq '_ci_' )
    {
        push( @where, sprintf "starttime>='%s'", POSIX::strftime( "%Y-%m-%d 00:00:00", localtime( time - 86400 * 30 ) ) );
        $order = 'order by starttime'
    }

    my @col = qw( id projectid uuid name user slave status starttime finishtime calltype runtime reason variable );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_jobx_task
                where projectid in ( $projectid ) %s $order", join( ',', @col ), @where ? ' and '.join( ' and ', @where ):'' ), \@col )};

    map{
        eval{ $_->{variable} = decode_base64( $_->{variable} ) } if defined $_->{variable};
        $_->{variable} = 'Error' if $@;
    }@$r;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

get '/task/:projectid/count' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $time = POSIX::strftime( "%Y-%m-00 00:00:00", localtime );
    my $r = eval{ 
        $api::mysql->query( "select status,count(*) from openc3_jobx_task where projectid='$param->{projectid}' and starttime>'$time' group by status" )};

    my %data = map{@$_}@$r;

    map{$data{$_}||=0}qw( success running fail );
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \%data };
};

# 按时间段统计
get '/task/:projectid/total_count' => sub {
    my $param = params();
    my $error = Format->new(
      projectid => qr/^\d+$/, 1,
      time_start => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
      time_end => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $r = eval{
        $api::mysql->query( "select status,count(*) from openc3_jobx_task where projectid='$param->{projectid}' and starttime>='$param->{time_start} 00:00:00' and starttime<='$param->{time_end} 23:59:59' group by status" )};

    return  +{ stat => $JSON::false, info => $@ } if $@;

    my %data = map{@$_}@$r;

    map{$data{$_}||=0}qw( success running fail );
    return +{ stat => $JSON::true, data => \%data };
};

get '/task/:projectid/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id uuid name user slave status starttime finishtime calltype runtime  pid starttimems finishtimems reason variable );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_jobx_task
                where uuid='$param->{uuid}' and projectid='$param->{projectid}'", join ',', @col ), \@col )};
    map{
        eval{ $_->{variable} = decode_base64( $_->{variable} ) } if defined $_->{variable};
        $_->{variable} = 'Error' if $@;
    }@$r;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0] };
};

#/task/:projectid/job/byname?jobname=jobname1
#group = groupname1
#variable = %hash
post '/task/:projectid/job/byname' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        jobname => [ 'mismatch', qr/'/ ], 1,
        group => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $point = 'openc3_jobx_write';
    if( $param->{jobname} =~ /^_ci_(\d+)_$/ )
    {
        my $cid = $1;
        $point = 'openc3_job_control' if $param->{group} eq "_ci_test_${cid}_" || $param->{group} eq "_ci_online_${cid}_";
    }
    else
    {
        my $ua = LWP::UserAgent->new();
        $ua->agent('Mozilla/9 [en] (Centos; Linux)');
    
        my %env = eval{ Util::envinfo( qw( appkey appname envname ) ) };
        return +{ stat => $JSON::false, info => "fromat error:$@" } if $@;
    
        $ua->default_header( map{ $_ => $env{$_} }qw( appname appkey ) );
     
        $ua->timeout( 10 );
        $ua->default_header ( 'Cache-control' => 'no-cache', 'Pragma' => 'no-cache' );
    
        my $url = "http://api.job.open-c3.org/task/$param->{projectid}/authorization/$param->{group}/$param->{jobname}";
        my $res = $ua->get( $url );
        my $cont = $res->content;

        return +{ stat => $JSON::false, info => "get authorization status fail" } unless $res->is_success;
        my $data = eval{JSON::from_json $cont};
        return +{ stat => $JSON::false, info => "get authorization no json" } if $@;
        return +{ stat => $JSON::false, info => "get authorization status, stat no true" } unless $data->{stat};

        $point = 'openc3_job_control' if $data->{data} eq 1;
    }

    my $pmscheck = api::pmscheck( $point, $param->{projectid} ); return $pmscheck if $pmscheck;

    my $slave = eval{ keepalive->new( $api::mysql )->slave() };
    return  +{ stat => $JSON::false, info => "get slave fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "system error: no slave" } unless defined $slave;

    my $uuid = uuid->new()->create_str;
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $calltype = $user =~ /\@app$/ ? 'api' : 'page';

    my $variable = $param->{variable} ? encode_base64( encode('UTF-8', YAML::XS::Dump $param->{variable}) ) : '';

    eval{ $api::auditlog->run( user => $user, title => 'START JOBX', content => "TREEID:$param->{projectid} JOBNAME:$param->{jobname} BATCHNAME:$param->{group}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( "insert into openc3_jobx_task (`projectid`,`uuid`,`name`,`group`,`user`,`slave`,`status`,`calltype`,`variable`) 
            values('$param->{projectid}','$uuid','$param->{jobname}','$param->{group}','$user','$slave', 'init','$calltype','$variable')" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, uuid => $uuid, data => $r };
};

put '/task/:projectid/:uuid/:control' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
        control => [ 'in', 'rollback', 'norollback' ], 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_control', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $x = eval{ $api::mysql->query( "select variable,starttimems from openc3_jobx_task where uuid='$param->{uuid}' and projectid='$param->{projectid}'" )};
    return +{ stat => $JSON::false, info => $@ } if $@;
    return  +{ stat => $JSON::false, info => "no find task" } unless $x && @$x;

    return +{ stat => $JSON::false, info => "role ne deploy" } unless uuid::get_role( $param->{uuid} ) eq 'deploy' ;

    return +{ stat => $JSON::false, info => "flowline has timed out, rollback is not allowed." } if time > $x->[0][1] + 604800;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $calltype = $user =~ /\@app$/ ? 'api' : 'page';


    return +{ stat => $JSON::false, info => "variable null" } unless my $variable = $x->[0][0];
       
    $variable = eval{ decode_base64( $variable ) };
    return +{ stat => $JSON::false, info => "decode variable fail:$@" } if $@;
    $variable = eval{ YAML::XS::Load( $variable ) };
    return +{ stat => $JSON::false, info => "yaml.load variable fail:$@" } if $@;
    return +{ stat => $JSON::false, info => "variable not HASH" } unless ref $variable  eq 'HASH';

    return +{ stat => $JSON::false, info => "variable nodefined _rollbackVersion_" } unless defined $variable->{_rollbackVersion_};
    my $v = delete $variable->{_rollbackVersion_};
    $variable->{version} = $v;
    $variable = encode_base64( encode('UTF-8', YAML::XS::Dump $variable) );
    my $ruuid = uuid::get_rollback_uuid( $param->{uuid} );

    eval{ $api::auditlog->run( user => $user, title => 'JOBX TASK ROLLBACK', content => sprintf( "TREEID:$param->{projectid} UUID:$param->{uuid} ROLLBACK:%s", $param->{control} eq 'rollback' ? 'Yes' : 'No'  ) ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{
        if( $param->{control} eq 'rollback' )
        {
            $api::mysql->execute(  "insert into openc3_jobx_task (`projectid`,`uuid`,`name`,`group`,`user`,`slave`,`status`,`calltype`,`variable`) select `projectid`,'$ruuid',`name`,`group`,'$user',`slave`,'init','$calltype','$variable' from openc3_jobx_task where uuid='$param->{uuid}'" );
        }
        else
        {
            $api::mysql->execute(  "insert into openc3_jobx_task (`projectid`,`uuid`,`name`,`group`,`user`,`slave`,`status`,`calltype`,`variable`) select `projectid`,'$ruuid',`name`,'_null_','$calltype','_null_','success','$calltype','$variable' from openc3_jobx_task where uuid='$param->{uuid}'" );
        }
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, info => "ok" };
};

any ['put', 'delete'] => '/task/:projectid/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'KILL JOBX', content => "TREEID:$param->{projectid} TASKUUID:$param->{uuid}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{ 
        $api::mysql->execute( "update openc3_jobx_subtask set status='cancel' where parent_uuid='$param->{uuid}' and status='init' 
                and parent_uuid in( select uuid from openc3_jobx_task where projectid='$param->{projectid}')"
        );
        $api::mysql->execute( "update openc3_jobx_subtask set confirm='task stop' where parent_uuid='$param->{uuid}' and confirm='WaitConfirm'
                and parent_uuid in( select uuid from openc3_jobx_task where projectid='$param->{projectid}')"
        );
    };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{
        $api::mysql->query( "select uuid from openc3_jobx_subtask where parent_uuid='$param->{uuid}' and status='running' 
                and parent_uuid in( select uuid from openc3_jobx_task where projectid='$param->{projectid}')" );
    };
    return +{ stat => $JSON::false, info => $@ } if $@;

    if( @$r )
    {
        my $subtask_uuid = $r->[0][0];

        my $ua = LWP::UserAgent->new();
        $ua->agent('Mozilla/9 [en] (Centos; Linux)');
    
        my %env = eval{ Util::envinfo( qw( appkey appname envname ) ) };
        return +{ stat => $JSON::false, info => "fromat error:$@" } if $@;
    
        $ua->default_header( map{ $_ => $env{$_} }qw( appname appkey) );
     
        $ua->timeout( 10 );
        $ua->default_header ( 'Cache-control' => 'no-cache', 'Pragma' => 'no-cache' );
    
        my $url = "http://api.job.open-c3.org/task/$param->{projectid}/$subtask_uuid";
        my $res = $ua->get( $url );
    
        my $cont = $res->content;

        return +{ stat => $JSON::false, info => "get subtask status fail" } unless $res->is_success;
        my $data = eval{JSON::from_json $cont};
        return +{ stat => $JSON::false, info => "get subtask status no json" }  if $@;
        return +{ stat => $JSON::false, info => "get subtask status, stat no true" } unless $data->{stat};

        return +{ stat => $JSON::false, info => "get subtask status, data no HASH" } unless $data->{data} && ref $data->{data} eq 'HASH';
 
        return +{ stat => $JSON::true, info => "subtask is done" } 
            if ( $data->{data}{status} && ( $data->{data}{status} eq 'success' || $data->{data}{status} eq 'fail') );

        return +{ stat => $JSON::false, info => "get subtask status, no slave" }  unless $data->{data}{slave};
        return +{ stat => $JSON::false, info => "get subtask status, slave format error" }  unless $data->{data}{slave} =~ /^[a-zA-Z0-9\.\-_]+$/;;

        $res = $ua->delete( "http://api.job.open-c3.org/slave/$data->{data}{slave}/killtask/$subtask_uuid" );
        return +{ stat => $JSON::false, info => "stop task fail" } unless $res->is_success;
        $data = eval{JSON::from_json $cont};
        return +{ stat => $JSON::false, info => "stop subtask status no json" }  if $@;

        return +{ stat => $JSON::false, info => "stop subtask status, stat no true" } unless $data->{stat};
    }

    return +{ stat => $JSON::true };
};

#count
get '/task/:projectid/analysis/last' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        count => qr/^\d+$/, 0,
        
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    $param->{count} ||= 10;

    my @col = qw( user runtime status name );
    my $r = eval{ $api::mysql->query( 
            sprintf( "select %s from openc3_jobx_task where projectid='$param->{projectid}' order by id desc limit $param->{count}", join ',',@col ), \@col
            )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

get '/task/:projectid/analysis/date' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $time = POSIX::strftime( "%Y-%m-%d 00:00:00", localtime( time - 2592000 ) );
    my $all = eval{ $api::mysql->query( "select DATE_FORMAT(starttime, '%Y-%m-%d') as x,count(*)  from openc3_jobx_task
            where projectid='$projectid' and starttime>'$time' group by x order by x" )};
    my $success = eval{ $api::mysql->query( "select DATE_FORMAT(starttime, '%Y-%m-%d') as x,count(*)  from openc3_jobx_task
            where projectid='$projectid' and status='success' and starttime>'$time' group by x order by x" )};

    my %success = map{ @$_ }@$success;
    my @data;
    map{  push @data, [ @$_, $success{$_->[0]}||0 ];}@$all;
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@data };
};


get '/task/:projectid/analysis/hour' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $time = POSIX::strftime( "%Y-%m-%d 00:00:00", localtime( time - 2592000 ) );
    my $r = eval{ 
        $api::mysql->query( "select DATE_FORMAT(starttime, '%H'),count(*)  from openc3_jobx_task where projectid='$projectid' and starttime>'$time' group by DATE_FORMAT(starttime, '%H')" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};


get '/task/:projectid/analysis/runtime' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $time = POSIX::strftime( "%Y-%m-%d 00:00:00", localtime( time - 2592000 ) );
    my $r = eval{ 
        $api::mysql->query( "select runtime from openc3_jobx_task where projectid='$projectid' and starttime>'$time'" )};

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

true;
