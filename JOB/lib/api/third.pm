package api::third;
use Dancer ':syntax';
use Dancer qw(cookie);
use JSON qw();
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

=pod

第三方调用/获取作业列表

=cut

post '/third/option/jobname' => sub {
    my $param = params();
    my $error = Format->new( 
        project_id => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $project_id = $param->{project_id};

    my $r = eval{ 
        $api::mysql->query( "select name from `openc3_job_jobs` where projectid='$project_id' and status='permanent'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => [map{@$_}@$r] };
};

=pod

第三方调用/获取作业变量信息

=cut

post '/third/option/variable' => sub {
    my $param = params();
    my $error = Format->new( 
        project_id => qr/^\d+$/, 1,
        jobname => [ 'mismatch', qr/'/ ], 1,
        exclude => qr/^[a-zA-Z0-9,_]+$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $exclude = '';
    if( $param->{exclude} )
    {
        $exclude = sprintf "and name not in( %s )", join ',',map{ "'$_'" }split /,/,$param->{exclude};
    }


    my $project_id = $param->{project_id};
    my @col = qw( name describe  );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_variable
                where jobuuid in ( select uuid from openc3_job_jobs where projectid='$param->{project_id}' and name='$param->{jobname}') and value='' $exclude", 
                    join ',',map{"`$_`"} @col ), \@col )};

    return +{ stat => $JSON::false, info => $@ }  if $@;
    my @data;
    map{ push @data, +{ var_name => $_->{name} , desc => $_->{describe}, placeholder => '', type => 'text' }}@$r;

    return +{ stat => $JSON::true, data => \@data };
};

sub makeuuid
{
    my %param = @_;
    $param{retry_count} = 0 unless $param{retry_count};
    my @x = ( 0 .. 9, 'a' .. 'z', 'A' .. 'Z' );
    my $retry_count = ( $param{retry_count} >= 0 && $param{retry_count} < @x ) ? $param{retry_count} : $#x;
    return substr( $param{uuid}, 0, 11 ).$x[$retry_count];
};

=pod

第三方调用/检查执行参数

=cut

post '/third/interface/dry-run' => sub {
    my $param = params();
    my $error = Format->new( 
        project_id => qr/^\d+$/, 1,
        uuid => qr/^[a-zA-Z0-9]{12}$/, 1,
        retry_count => qr/^\d+$/,0
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $params = $param->{params};

    return  +{ stat => $JSON::false, info => "params undef" } unless $params;
    return  +{ stat => $JSON::false, info => "params no HASH" } unless ref $params eq 'HASH';

    $error = Format->new( 
        jobname => [ 'mismatch', qr/'/ ], 1,
    )->check( %$params );
    return  +{ stat => $JSON::false, info => "check params format fail $error" } if $error;

    return +{ stat => $JSON::false, info => "check params variable no HASH" }
        if $params->{variable} && ref $params->{variable} ne 'HASH';

    my $slave = eval{ keepalive->new( $api::mysql )->slave() };
    return  +{ stat => $JSON::false, info => "get slave fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "system error: no slave" } unless defined $slave;

    my $uuid = makeuuid( %$param );

    my $x = eval{ $api::mysql->query( "select uuid from openc3_job_task where uuid='$uuid'" ) };
    return  +{ stat => $JSON::false, info => "get data error from db: $@" }  if $@;
    return  +{ stat => $JSON::false, info => "get data error from db" } unless defined $x && ref $x eq 'ARRAY';
    return  +{ stat => $JSON::false, info => "uuid has already existed in the task" } if @$x;
   

    $x = eval{ $api::mysql->query( "select uuid from openc3_job_jobs where name='$params->{jobname}' and projectid=$param->{project_id}" ) };
    return  +{ stat => $JSON::false, info => "get data error from db: $@" }  if $@;
    return  +{ stat => $JSON::false, info => "get data error from db" } unless defined $x && ref $x eq 'ARRAY';
    return  +{ stat => $JSON::false, info => "project_id, jobname nomatch" } unless @$x;

    my $jobuuid = $x->[0][0];
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $calltype = $user =~ /\@app$/ ? 'api' : 'page';

    my $variable = $params->{variable} ? encode_base64( encode('UTF-8', YAML::XS::Dump $params->{variable}) ) : '';

    return +{ stat => $JSON::true, uuid => $uuid, msg => "ok" };
};

=pod

第三方调用/执行作业

=cut

post '/third/interface/invoke' => sub {
    my $param = params();
    my $error = Format->new( 
        project_id => qr/^\d+$/, 1,
        uuid => qr/^[a-zA-Z0-9]{12}$/, 1,
        retry_count => qr/^\d+$/,0
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $params = $param->{params};

    return  +{ stat => $JSON::false, info => "params undef" } unless $params;
    return  +{ stat => $JSON::false, info => "params no HASH" } unless ref $params eq 'HASH';

    $error = Format->new( 
        jobname => [ 'mismatch', qr/'/ ], 1,
    )->check( %$params );
    return  +{ stat => $JSON::false, info => "check params format fail $error" } if $error;

    return +{ stat => $JSON::false, info => "check params variable no HASH" }
        if $params->{variable} && ref $params->{variable} ne 'HASH';

    my $slave = eval{ keepalive->new( $api::mysql )->slave() };
    return  +{ stat => $JSON::false, info => "get slave fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "system error: no slave" } unless defined $slave;

    my $uuid = makeuuid( %$param );
    my $x = eval{ $api::mysql->query( "select uuid from openc3_job_task where uuid='$uuid'" ) };
    return  +{ stat => $JSON::false, info => "get data error from db: $@" }  if $@;
    return  +{ stat => $JSON::false, info => "get data error from db" } unless defined $x && ref $x eq 'ARRAY';
    return  +{ stat => $JSON::true, info => "This task has been successfully created" } if @$x;
   

    $x = eval{ $api::mysql->query( "select uuid from openc3_job_jobs where name='$params->{jobname}' and projectid=$param->{project_id}" ) };
    return  +{ stat => $JSON::false, info => "get data error from db: $@" }  if $@;
    return  +{ stat => $JSON::false, info => "get data error from db" } unless defined $x && ref $x eq 'ARRAY';
    return  +{ stat => $JSON::false, info => "project_id, jobname nomatch" } unless @$x;

    my $jobuuid = $x->[0][0];
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $calltype = $user =~ /\@app$/ ? 'api' : 'page';

    my $variable = $params->{variable} ? encode_base64( encode('UTF-8', YAML::XS::Dump $params->{variable}) ) : '';

    my $r = eval{ 
        $api::mysql->execute( "insert into openc3_job_task (`projectid`,`uuid`,`name`,`user`,`slave`,`status`,`calltype`,`jobtype`,`jobuuid`,`mutex`,`variable`) 
            values('$param->{project_id}','$uuid','$params->{jobname}','$user','$slave', 'init','$calltype','jobs','$jobuuid','','$variable')" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, uuid => $uuid, data => $r };
};

=pod

第三方调用/查询作业状态

=cut

post '/third/interface/query' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
        retry_count => qr/^\d+$/,0
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $uuid = makeuuid( %$param );
    my @col = qw(  status reason projectid );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_task
                where uuid='$uuid'", join ',', @col ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;

    return +{ stat => $JSON::false, info => "no find uuid" } unless $r && @$r;
    my $status = $r->[0]{status};
    my $reason = $r->[0]{reason} || '';
    my $projectid = $r->[0]{projectid};

    $reason = "Wait for manual treatment, reason: $reason" if $status eq 'waiting';
    $status = $status eq 'success' ? 'complete' : $status eq 'fail' ? 'fail' : 'running';

    my %ctrl; %ctrl = (
        ctrl => ["http://api.job.open-c3.org/#/taskstatusforflow/${projectid}/$uuid"],
    ) if $r->[0]{status} eq 'waiting';

    my $rp = eval{ $api::mysql->query( "select status from openc3_job_subtask where parent_uuid='$uuid'" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my @progress = (0,0); map{ $progress[1]++; $progress[0]++ if $_->[0] }@$rp;

    return +{ 
        stat => $JSON::true, status => $status, msg => $reason, 
        link => "http://api.job.open-c3.org/#/work/taskstatus/${projectid}/$uuid",
        progress => \@progress,
        %ctrl,
    };
};

=pod

第三方调用/停止作业

=cut

post '/third/interface/stop' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
        retry_count => qr/^\d+$/,0
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $uuid = makeuuid( %$param );
    my $x = eval{ $api::mysql->query( "select projectid,slave,status from openc3_job_task where uuid='$uuid'" )};
    return +{ stat => $JSON::false, info => $@ } if $@;
    return  +{ stat => $JSON::false, info => "no find task" } unless $x && @$x;
    my ( $project_id, $slave, $status )  = @{$x->[0]};

    return +{ stat => $JSON::true, info => "jobx uuid:$uuid status: $status" } if $status eq 'fail' || $status eq 'success';

    my $ua = LWP::UserAgent->new();
    $ua->agent('Mozilla/9 [en] (Centos; Linux)');
    
    my %env = eval{ Util::envinfo( qw( appkey appname envname ) ) };
    return +{ stat => $JSON::false, info => $@ } if $@;
    
    $ua->default_header( map{ $_ => $env{$_} }qw( appname appkey) );
    
    $ua->timeout( 10 );
    $ua->default_header ( 'Cache-control' => 'no-cache', 'Pragma' => 'no-cache' );
    
    my $url = "http://api.job.open-c3.org/slave/$slave/killtask/$uuid";
    my $res = $ua->delete( $url );
    return +{ stat => $JSON::false, info => "stop task fail", call => $url, 'content' => $res->content  } unless $res->is_success;
    my $data = eval{JSON::from_json $res->content};
    return +{ stat => $JSON::false, info => "stop subtask status no json", call => $url, 'content' => $res->content }  if $@;

    return +{ stat => $JSON::false, info => "stop subtask status, stat no true", call => $url, 'content' => $res->content } unless $data->{stat};

    return +{ stat => $JSON::false, uuid => $uuid };
};

true;
