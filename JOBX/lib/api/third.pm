package api::third;
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
use FindBin qw( $RealBin );
use Util;

my %env;
BEGIN{ %env = Util::envinfo( qw( envname domainname ) ); };

post '/third/option/groupname' => sub {
    my $param = params();
    my $error = Format->new( 
        project_id => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_write', $param->{project_id} ); return $pmscheck if $pmscheck;

    my $project_id = $param->{project_id};

    my $r = eval{ 
        $api::mysql->query( "select name from `openc3_jobx_group` where projectid='$project_id'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => [map{@$_}@$r] };
};

sub makeuuid
{
    my %param = @_;
    $param{retry_count} = 0 unless $param{retry_count};
    my @x = ( 'a' .. 'z' );
    my $retry_count = ( $param{retry_count} >= 0 && $param{retry_count} < @x ) ? $param{retry_count} : $#x;
    return substr( $param{uuid}, 0, 11 ).$x[$retry_count];
};

sub getjobstatus
{
    my ( $projectid, $uuid )= @_;
    my $ua = LWP::UserAgent->new();
    $ua->agent('Mozilla/9 [en] (Centos; Linux)');
    
    my %env = eval{ Util::envinfo( qw( appkey appname envname ) ) };
    return +{ stat => $JSON::false, info => "fromat error $@" } if $@;
    
    $ua->default_header( map{ $_ => $env{$_} }qw( appname appkey) );
    
    $ua->timeout( 10 );
    $ua->default_header ( 'Cache-control' => 'no-cache', 'Pragma' => 'no-cache' );
    
    my $url = "http://api.job.open-c3.org/task/$projectid/$uuid";
    my $res = $ua->get( $url );
    
    my $cont = $res->content;
    
    return +{ stat => $JSON::false, info => "get subtask status fail", call => $url, content => $cont } unless $res->is_success;
    my $data = eval{JSON::from_json $cont};
    return +{ stat => $JSON::false, info => "get subtask status no json", call => $url, content => $cont }  if $@;
    return +{ stat => $JSON::false, info => "get subtask status, stat no true", call => $url, content => $cont } unless $data->{stat};
    
    return +{ stat => $JSON::false, info => "get subtask status, data no HASH", call => $url, content => $cont }
        unless $data->{data} && ref $data->{data} eq 'HASH';
    
    return +{ stat => $JSON::false, info => "nofind job status" }  unless $data->{data}{status};
    return +{ status => $data->{data}{status} };
};

post '/third/interface/dry-run' => sub {
    my $param = params();
    my $error = Format->new( 
        project_id => qr/^\d+$/, 1,
        uuid => qr/^[a-zA-Z0-9]{12}$/, 1,
        retry_count => qr/^\d+$/,0
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_write', $param->{project_id} ); return $pmscheck if $pmscheck;

    my $params = $param->{params};

    return  +{ stat => $JSON::false, info => "params undef" } unless $params;
    return  +{ stat => $JSON::false, info => "params no HASH" } unless ref $params eq 'HASH';

    $error = Format->new( 
        jobname => [ 'mismatch', qr/'/ ], 1,
        group => [ 'mismatch', qr/'/ ], 1,
    )->check( %$params );
    return  +{ stat => $JSON::false, info => "check params format fail $error" } if $error;

    return +{ stat => $JSON::false, info => "check params variable no HASH" }
        if $params->{variable} && ref $params->{variable} ne 'HASH';

    my $slave = eval{ keepalive->new( $api::mysql )->slave() };
    return  +{ stat => $JSON::false, info => "get slave fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "system error: no slave" } unless defined $slave;

    my $uuid = makeuuid( %$param );
    my $x = eval{ $api::mysql->query( "select uuid from openc3_jobx_task where uuid='$uuid'" ) };
    return  +{ stat => $JSON::false, info => "get data error from db: $@" }  if $@;
    return  +{ stat => $JSON::false, info => "get data error from db" } unless defined $x && ref $x eq 'ARRAY';
    return  +{ stat => $JSON::flase, info => "uuid has already existed in the task" } if @$x;
 
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $calltype = $user =~ /\@app$/ ? 'api' : 'page';

    my $variable = $params->{variable} ? encode_base64( encode('UTF-8', YAML::XS::Dump $params->{variable}) ) : '';

    return +{ stat => $JSON::true, uuid => $uuid, msg => 'ok' };
};


post '/third/interface/invoke' => sub {
    my $param = params();
    my $error = Format->new( 
        project_id => qr/^\d+$/, 1,
        uuid => qr/^[a-zA-Z0-9]{12}$/, 1,
        retry_count => qr/^\d+$/,0
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_write', $param->{project_id} ); return $pmscheck if $pmscheck;

    my $params = $param->{params};

    return  +{ stat => $JSON::false, info => "params undef" } unless $params;
    return  +{ stat => $JSON::false, info => "params no HASH" } unless ref $params eq 'HASH';

    $error = Format->new( 
        jobname => [ 'mismatch', qr/'/ ], 1,
        group => [ 'mismatch', qr/'/ ], 1,
    )->check( %$params );
    return  +{ stat => $JSON::false, info => "check params format fail $error" } if $error;

    return +{ stat => $JSON::false, info => "check params variable no HASH" }
        if $params->{variable} && ref $params->{variable} ne 'HASH';

    my $slave = eval{ keepalive->new( $api::mysql )->slave() };
    return  +{ stat => $JSON::false, info => "get slave fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "system error: no slave" } unless defined $slave;

    my $uuid = makeuuid( %$param );
    my $x = eval{ $api::mysql->query( "select uuid from openc3_jobx_task where uuid='$uuid'" ) };
    return  +{ stat => $JSON::false, info => "get data error from db: $@" }  if $@;
    return  +{ stat => $JSON::false, info => "get data error from db" } unless defined $x && ref $x eq 'ARRAY';
    return  +{ stat => $JSON::true, info => "This task has been successfully created" } if @$x;
 
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $calltype = $user =~ /\@app$/ ? 'api' : 'page';

    my $variable = $params->{variable} ? encode_base64( encode('UTF-8', YAML::XS::Dump $params->{variable}) ) : '';

    my $r = eval{ 
        $api::mysql->execute( "insert into openc3_jobx_task (`projectid`,`uuid`,`name`,`group`,`user`,`slave`,`status`,`calltype`,`variable`) 
            values('$param->{project_id}','$uuid','$params->{jobname}','$params->{group}','$user','$slave', 'init','$calltype','$variable')" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, uuid => $uuid, data => $r };
};


post '/third/interface/query' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
        retry_count => qr/^\d+$/,0
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_write', 0 ); return $pmscheck if $pmscheck;

    my $uuid = makeuuid( %$param );
    my $ruuid = uuid::get_rollback_uuid( $uuid );
    my @col = qw(  status projectid slave );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_jobx_task
                where uuid in ( '$uuid', '$ruuid' ) order by id", join ',', @col ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;

    return +{ stat => $JSON::false, info => "no find uuid" } unless $r && @$r;

    if( @$r == 1 )
    {

        my $status = $r->[0]{status};
        my $projectid = $r->[0]{projectid};

        my $reason = '';
        my %ctrl; %ctrl = (
            ctrl => [undef,"http://$env{envname}.jobx.$env{'domainname'}/#/detailforflow/${projectid}/$uuid"],
        );

        my $rp = eval{ $api::mysql->query( "select starttime,status,uuid from openc3_jobx_subtask where parent_uuid='$uuid'" ); };
        return +{ stat => $JSON::false, info => $@ } if $@;
        my ( $finish, @progress ) = (0,0,0);
        map{
            $progress[1]++;
            $progress[0]++ if $_->[0]; 
            $finish ++ if $_->[1] && ( $_->[1] eq 'success' || $_->[1] eq 'fail' )
        }@$rp;

        $ctrl{ctrl}[0] = $ctrl{ctrl}[1] if $finish eq $progress[1];
        
        for( @$rp )
        {
            my ( undef, $tstatus, $tuuid ) = @$_;
            if( $tstatus && $tstatus eq 'running' )
            {
                my $js = getjobstatus( $projectid, $tuuid );
                return $js unless $js && $js->{status};
                %ctrl = ( ctrl => ["http://$env{envname}.job.$env{'domainname'}/#/taskstatusforflow/${projectid}/$tuuid","http://$env{envname}.jobx.$env{'domainname'}/#/detailforflow/${projectid}/$uuid"] ) if $js->{status} eq 'waiting';
                last;
            }
        }

        return +{ stat => $JSON::true, status => 'running', msg => $reason, type => 'deploy',
            link => "http://$env{envname}.jobx.$env{'domainname'}/#/task/detail/${projectid}/$uuid",
            progress => \@progress,
            %ctrl,
        };

    }
    else
    {
        my $status = $r->[0]{status};
        my $projectid = $r->[0]{projectid};

        my $rstatus = $r->[1]{status};
        my $rslave = $r->[1]{slave};

        if( $rslave  eq '_null_' )
        {
            $status = $status eq 'success' ? 'complete' : $status eq 'fail' ? 'fail' : 'running';
            my $x = eval{ 
                $api::mysql->query( "select count(*) from openc3_jobx_subtask where parent_uuid='$uuid' and confirm='WaitConfirm'" )};

            return +{ stat => $JSON::false, info => $@ } if $@;

            my $reason = '';
            $reason = "Wait for manual treatment" if $x->[0][0]>0;

            my %ctrl; %ctrl = (
                ctrl => ["http://$env{envname}.jobx.$env{'domainname'}/#/detailforflow/${projectid}/$uuid"],
            ) if $x->[0][0]>0;
    
            my $rp = eval{ $api::mysql->query( "select starttime,status,uuid from openc3_jobx_subtask where parent_uuid='$uuid'" ); };
            return +{ stat => $JSON::false, info => $@ } if $@;
            my @progress = (0,0); map{ $progress[1]++; $progress[0]++ if $_->[0] }@$rp;

            for( @$rp )
            {
                my ( undef, $tstatus, $tuuid ) = @$_;
                if( $tstatus && $tstatus eq 'running' )
                {
                    my $js = getjobstatus( $projectid, $tuuid );
                    return $js unless $js && $js->{status};
                    %ctrl = ( ctrl => ["http://$env{envname}.job.$env{'domainname'}/#/taskstatusforflow/${projectid}/$tuuid"] ) if $js->{status} eq 'waiting';
                    last;
                }
            }
    
            return +{ stat => $JSON::true, status => $status, msg => $reason,  type => 'deployonly',
                link => "http://$env{envname}.jobx.$env{'domainname'}/#/task/detail/${projectid}/$uuid",
                progress => \@progress,
                %ctrl,
            };
        }
        else
        {
            $rstatus = $rstatus eq 'success' ? 'complete' : $rstatus eq 'fail' ? 'fail' : 'running';
            my $x = eval{ 
                $api::mysql->query( "select count(*) from openc3_jobx_subtask where parent_uuid='$ruuid' and confirm='WaitConfirm'" )};

            return +{ stat => $JSON::false, info => $@ } if $@;

            my $reason = '';
            $reason = "Wait for manual treatment" if $x->[0][0]>0;

            my %ctrl; %ctrl = (
                ctrl => ["http://$env{envname}.jobx.$env{'domainname'}/#/detailforflow/${projectid}/$uuid"],
            ) if $x->[0][0]>0;
    
            my $rp = eval{ $api::mysql->query( "select starttime,status,uuid from openc3_jobx_subtask where parent_uuid='$uuid'" ); };
            return +{ stat => $JSON::false, info => $@ } if $@;
            my @progress = (0,0); map{ $progress[1]++; $progress[0]++ if $_->[0] }@$rp;

            for( @$rp )
            {
                my ( undef, $tstatus, $tuuid ) = @$_;
                if( $tstatus && $tstatus eq 'running' )
                {
                    my $js = getjobstatus( $projectid, $tuuid );
                    return $js unless $js && $js->{status};
                    %ctrl = ( ctrl => ["http://$env{envname}.job.$env{'domainname'}/#/taskstatusforflow/${projectid}/$tuuid" ] ) if $js->{status} eq 'waiting';
                    last;
                }
            }

            return +{ stat => $JSON::true, status => $rstatus, msg => $reason, type => 'rollback',
                link => "http://$env{envname}.jobx.$env{'domainname'}/#/task/detail/${projectid}/$ruuid",
                progress => \@progress,
                %ctrl,
            };
        }

    }

};

post '/third/interface/stop' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
        retry_count => qr/^\d+$/,0
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_write', 0 ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $uuid = makeuuid( %$param );
    my $ruuid = uuid::get_rollback_uuid( $uuid );

    my $x = eval{ $api::mysql->query( "select uuid,projectid,status,slave from openc3_jobx_task where uuid in ( '$uuid', '$ruuid' ) order by id" )};
    return +{ stat => $JSON::false, info => $@ } if $@;

    return  +{ stat => $JSON::false, info => "no find task" } unless $x && @$x;

    if( @$x != 2 )
    {
         eval{
             $api::mysql->execute(  "insert into openc3_jobx_task (`projectid`,`uuid`,`name`,`group`,`user`,`slave`,`status`,`calltype`,`variable`) values('$x->[0][0]','$ruuid','_skip_','_null_','sys','_null_', 'success','sys','')" );
         };
         return +{ stat => $JSON::false, info => $@ } if $@;
         $x = eval{ $api::mysql->query( "select uuid,projectid,status,slave from openc3_jobx_task where uuid in ( '$uuid', '$ruuid' ) order by id" )};
         return +{ stat => $JSON::false, info => $@ } if $@;
         return +{ stat => $JSON::false, info => "nofind rollback uuid in database" } if @$x != 2;
    }

    my ( $project_id, $status );
    ( $uuid, $project_id, $status ) = $x->[1][3] eq '_null_' ? @{$x->[0]} : @{$x->[1]};


    return +{ stat => $JSON::true, info => "jobx uuid:$uuid status: $status" } if $status eq 'fail' || $status eq 'success';
    
    eval{ 
        $api::mysql->execute( "update openc3_jobx_subtask set status='cancel' where parent_uuid='$uuid' and status='init' 
                and parent_uuid in( select uuid from openc3_jobx_task where projectid='$project_id')"
        );
        $api::mysql->execute( "update openc3_jobx_subtask set confirm='task stop' where parent_uuid='$uuid' and confirm='WaitConfirm'
                and parent_uuid in( select uuid from openc3_jobx_task where projectid='$project_id')"
        );
 
    };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{
        $api::mysql->query( "select uuid from openc3_jobx_subtask where parent_uuid='$uuid' and status='running' 
                and parent_uuid in( select uuid from openc3_jobx_task where projectid='$project_id')" );
    };
    return +{ stat => $JSON::false, info => $@ } if $@;

    if( @$r )
    {
        my $subtask_uuid = $r->[0][0];

        my $ua = LWP::UserAgent->new();
        $ua->agent('Mozilla/9 [en] (Centos; Linux)');
    
        my %env = eval{ Util::envinfo( qw( appkey appname envname ) ) };
        return +{ stat => $JSON::false, info => "fromat error $@" } if $@;
    
        $ua->default_header( map{ $_ => $env{$_} }qw( appname appkey) );
     
        $ua->timeout( 10 );
        $ua->default_header ( 'Cache-control' => 'no-cache', 'Pragma' => 'no-cache' );
    
        my $url = "http://api.job.open-c3.org/task/$project_id/$subtask_uuid";
        my $res = $ua->get( $url );
    
        my $cont = $res->content;

        return +{ stat => $JSON::false, info => "get subtask status fail", call => $url, content => $cont } unless $res->is_success;
        my $data = eval{JSON::from_json $cont};
        return +{ stat => $JSON::false, info => "get subtask status no json", call => $url, content => $cont }  if $@;
        return +{ stat => $JSON::false, info => "get subtask status, stat no true", call => $url, content => $cont } unless $data->{stat};

        return +{ stat => $JSON::false, info => "get subtask status, data no HASH", call => $url, content => $cont }
            unless $data->{data} && ref $data->{data} eq 'HASH';
 
        return +{ stat => $JSON::false, info => "subtask is done" } 
            if ( $data->{data}{status} && ( $data->{data}{status} eq 'success' || $data->{data}{status} eq 'fail') );

        return +{ stat => $JSON::false, info => "get subtask status, no slave" }  unless $data->{data}{slave};
        return +{ stat => $JSON::false, info => "get subtask status, slave format error" }  unless $data->{data}{slave} =~ /^[a-zA-Z0-9\.\-_]+$/;;

        $url = "http://api.job.open-c3.org/slave/$data->{data}{slave}/killtask/$subtask_uuid";
        $res = $ua->delete( $url );

        $cont = $res->content;

        return +{ stat => $JSON::false, info => "stop task fail", call => $url, content => $cont } unless $res->is_success;
        $data = eval{JSON::from_json $cont};
        return +{ stat => $JSON::false, info => "stop subtask status no json", call => $url, content => $cont }  if $@;

        return +{ stat => $JSON::false, info => "stop subtask status, stat no true", call => $url, content => $cont } unless $data->{stat};
    }

    return +{ stat => $JSON::false, uuid => $uuid, msg => 'stoping' };
};

true;
