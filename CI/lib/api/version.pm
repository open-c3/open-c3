package api::version;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use uuid;

our $showcount;

BEGIN{
    my $x = `c3mc-sys-ctl ci.default.showcount`;
    chomp $x;
    $showcount = $x && $x =~ /^\d+$/ ? $x : 5;
};

=pod

流水线/获取单个流水线的版本列表/简单列表

=cut

get '/v/:groupid/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid}  ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $r = eval{ 
        $api::mysql->query( 
             "select name from openc3_ci_version where projectid='$projectid' order by create_time desc,id desc" )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => , [map{$_->[0] }@$r] };
};

=pod

流水线/获取单个流水线的版本列表/详细数据

=cut

get '/version/:groupid/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid}  ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( id projectid uuid name user slave status starttimems finishtimems 
            starttime  finishtime calltype pid runtime reason create_time tagger taginfo
    );
    my $limit = $param->{limit} ? "limit $showcount" : "";
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_version where projectid='$projectid' order by create_time desc,id desc $limit", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r ||[] };
};

=pod

流水线/获取单个版本的详情

=cut

get '/versiondetail/:projectid/:version' => sub {
    my $param = params();
    my $error = Format->new(
        projectid => qr/^\d+$/, 1,
        version => [ 'mismatch', qr/'/ ], 1
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid}  ); return $pmscheck if $pmscheck;

    my @col = qw( id projectid uuid name user slave status starttimems finishtimems 
            starttime  finishtime calltype pid runtime reason create_time tagger taginfo
    );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_version where projectid='$param->{projectid}' and name='$param->{version}'", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => @$r ? $r->[0] : +{} };
};

=pod

流水线/一次获取多个流水线下的版本信息

=cut

get '/versions' => sub {
    my $param = params();
    my $error = Format->new( projectids => qr/^[0-9\,]+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $projectids = $param->{projectids};

    my @col = qw(projectid name status starttime finishtime);
    my @project_ids = split(/,/, $projectids);
    my %results = ();
    map{
        my $r = eval{
            $api::mysql->query(
                sprintf( "select %s from openc3_ci_version where status!='done' and projectid in 
                    (select id from openc3_ci_project where id in ('$_') and status =True) order by id desc",
                    join( ',', @col)), \@col )};
        $results{$_} = $r ||[];
        }@project_ids;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \%results};
};

=pod

流水线/终止流水线下所有待运行的构建

=cut

put '/version/:groupid/:projectid/stop_project' => sub {
    my $param = params();
    my $error = Format->new(
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_control', $param->{groupid}  ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ),
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'STOP ALL BUILD', content => "TREEID:$param->{groupid} FLOWLINEID:$param->{projectid}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{
        $api::mysql->execute( "update openc3_ci_version set status='done',reason='off by $user'
            where projectid=$projectid and  status='init'");
    };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

流水线/触发某个版本的构建

=cut

put '/version/:groupid/:projectid/:uuid/build' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_control', $param->{groupid}  ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ),
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $running = eval{ $api::mysql->query( "select name from openc3_ci_version where projectid='$param->{projectid}' and status in ( 'init', 'running' )")};
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::false, info => "There are already tasks[$running->[0][0]] running. Please try again later." } if @$running > 0;

    my $tagname = eval{ $api::mysql->query( "select name from openc3_ci_version where uuid='$param->{uuid}'")};
    eval{ $api::auditlog->run( user => $user, title => 'START BUILD', content => "TREEID:$param->{groupid} FLOWLINEID:$param->{projectid} TAG:$tagname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{ 
        $api::mysql->execute( "update openc3_ci_version set status='init',user='$user',reason='call by page',pid=null,finishtime=null,finishtimems=null
            where uuid='$param->{uuid}' and ( status='fail' || status='success' || status='done')");
    };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

流水线/CI调用统计/调用类型

按照调用类型进行统计

=cut

get '/version/:groupid/:projectid/count/calltype' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid}  ); return $pmscheck if $pmscheck;

    my $time = POSIX::strftime( "%Y-%m-00 00:00:00", localtime );
    my $r = eval{
        $api::mysql->query( "select calltype,count(id) from openc3_ci_version where projectid='$param->{projectid}' group by calltype" )};
    my %data = map{@$_}@$r;

    map{$data{$_}||=0}qw( crontab webhook manmade );
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \%data };
};

=pod

流水线/CI调用统计/任务状态

按照任务状态进行统计

=cut

get '/version/:groupid/:projectid/count/status' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid}  ); return $pmscheck if $pmscheck;

    my $time = POSIX::strftime( "%Y-%m-00 00:00:00", localtime );
    my $r = eval{
        $api::mysql->query( "select status,count(id) from openc3_ci_version where projectid='$param->{projectid}' group by status" )};
    my %data = map{@$_}@$r;

    map{$data{$_}||=0}qw( running done );
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \%data };
};

=pod

流水线/CI调用统计/运行时长

按照运行时长进行统计

=cut

get '/version/:groupid/:projectid/analysis/runtime' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid}  ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $time = POSIX::strftime( "%Y-%m-%d 00:00:00", localtime( time - 2592000 ) );
    my $r = eval{ 
        $api::mysql->query( "select runtime from openc3_ci_version where projectid='$projectid' and starttime>'$time'" )};

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

流水线/CI调用统计/按天统计

按照每天执行次数进行统计

=cut

get '/version/:groupid/:projectid/analysis/date' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid}  ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $time = POSIX::strftime( "%Y-%m-%d 00:00:00", localtime( time - 2592000 ) );
    my $all = eval{ $api::mysql->query( "select DATE_FORMAT(starttime, '%Y-%m-%d') as x,count(*) from openc3_ci_version
            where projectid='$projectid' and starttime>'$time' group by x order by x" )};
    my $success = eval{ $api::mysql->query( "select DATE_FORMAT(starttime, '%Y-%m-%d') as x,count(*)  from openc3_ci_version
            where projectid='$projectid' and status='success' and starttime>'$time' group by x order by x" )};

    my %success = map{ @$_ }@$success;
    my @data;
    map{  push @data, [ @$_, $success{$_->[0]}||0 ];}@$all;
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@data };
};

=pod

流水线/CI调用统计/最后几条

默认显示最后10条

=cut

get '/version/:groupid/:projectid/analysis/last' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        count => qr/^\d+$/, 0,
        
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid}  ); return $pmscheck if $pmscheck;

    $param->{count} ||= 10;

    my @col = qw( user runtime status name );
    my $r = eval{ $api::mysql->query( 
            sprintf( "select %s from openc3_ci_version where projectid='$param->{projectid}' order by id desc limit $param->{count}", join ',',@col ), \@col
            )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

流水线/手动提交版本

=cut

post '/version/:groupid/:projectid/record' => sub {
    my $param = params();
    my $error = Format->new( 
        groupid   => qr/^\d+$/, 1,
        projectid => qr/^\d+$/, 1,
        version   => qr/[a-zA-Z][a-zA-Z0-9\.\-_@]*/, 1,
        describe  => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_control', $param->{groupid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'RECORD FLOWLINE CI', content => "TREEID:$param->{groupid} FLOWLINEID:$projectid NAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $starts = time;
    my $start  = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime($starts) );
    my $ends   = $starts + 1;
    my $end    = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime($ends) );
    my $uuid   = uuid->new()->create_str;

    eval{ 
        $api::mysql->execute(
            "insert into openc3_ci_version 
               ( `projectid` ,`uuid` ,`name`             ,`user` ,`slave`            ,`status` ,`starttimems`,`finishtimems`,`starttime`,`finishtime`,`calltype`,`pid`,`runtime`,`tagger`,`taginfo`           ,`reason`      ,`create_time`)
         values( '$projectid','$uuid','$param->{version}','$user','openc3-srv-docker','success','$starts'    ,'$ends'       ,'$start'   ,'$end'      ,'record'  ,NULL ,'1'      ,'$user' ,'$param->{describe}','call by page','$start'     )");
    };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
