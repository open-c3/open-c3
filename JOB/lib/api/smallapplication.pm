package api::smallapplication;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

=pod

轻应用/获取列表

=cut

get '/smallapplication/bytreeid/:treeid' => sub {
    my $param = params();
    my $error = Format->new( 
        treeid => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my @col = qw( id jobid type title describe parameter edit_user create_user edit_time create_time treeid projectid jobname );
    my $r = eval{ $api::mysql->query( "select openc3_job_smallapplication.*,openc3_job_jobs.projectid,openc3_job_jobs.name from openc3_job_smallapplication, openc3_job_jobs where openc3_job_jobs.id=openc3_job_smallapplication.jobid and openc3_job_smallapplication.treeid in( 0, $param->{treeid} ) order by id", \@col )};
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

轻应用/获取详情

=cut

get '/smallapplication/:id' => sub {
    my $param = params();
    my $error = Format->new( id => qr/^\d+$/, 1,)->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my @col = qw( id jobid type title describe parameter edit_user create_user edit_time create_time treeid projectid jobname );
    my $r = eval{ $api::mysql->query( "select openc3_job_smallapplication.*,openc3_job_jobs.projectid,openc3_job_jobs.name from openc3_job_smallapplication, openc3_job_jobs where openc3_job_jobs.id=openc3_job_smallapplication.jobid and openc3_job_smallapplication.id in(  $param->{id} ) order by id", \@col )};
 
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0] };
};

=pod

轻应用/创建轻应用

=cut

post '/smallapplication' => sub {
    my $param = params();
    my $error = Format->new( 
        jobid => qr/^\d+$/, 1,
        treeid => qr/^\d+$/, 1,
        type => [ 'mismatch', qr/'/ ], 1,
        title => [ 'mismatch', qr/'/ ], 1,
        describe => [ 'mismatch', qr/'/ ], 1,
        parameter => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    eval{ $api::auditlog->run( user => $user, title => 'CREATE SMALLAPPLICATION', content => "NAME:$param->{title}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( 
            "insert into openc3_job_smallapplication (`jobid`,`type`,`title`,`describe`,`parameter`,`create_user`,`edit_user`,`edit_time`,`treeid`)
                 values('$param->{jobid}', '$param->{type}', '$param->{title}', '$param->{describe}', '$param->{parameter}', '$user', '$user', '$time','$param->{treeid}')")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

轻应用/编辑轻应用

=cut

post '/smallapplication/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
        jobid => qr/^\d+$/, 1,
        treeid => qr/^\d+$/, 1,
        type => [ 'mismatch', qr/'/ ], 1,
        title => [ 'mismatch', qr/'/ ], 1,
        describe => [ 'mismatch', qr/'/ ], 1,
        parameter => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $smallapplicationname = eval{ $api::mysql->query( "select name from openc3_job_smallapplication where id='$param->{id}'")};
    eval{ $api::auditlog->run( user => $user, title => 'EDIT SMALLAPPLICATION', content => "NAME:$smallapplicationname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( "update openc3_job_smallapplication set `jobid`='$param->{jobid}',`type`='$param->{type}',`title`='$param->{title}',`describe`='$param->{describe}',`parameter`='$param->{parameter}',edit_user='$user',edit_time='$time',treeid='$param->{treeid}' where id='$param->{id}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

轻应用/删除轻应用

=cut

del '/smallapplication/:id' => sub {
    my $param = params();
    my $error = Format->new( id => qr/^\d+$/, 1,)->check( %$param ); 
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $smallapplicationname = eval{ $api::mysql->query( "select name from openc3_job_smallapplication where id='$param->{id}'")};
    eval{ $api::auditlog->run( user => $user, title => 'DELETE SMALLAPPLICATION', content => "NAME:$smallapplicationname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ $api::mysql->execute( "delete from openc3_job_smallapplication where id='$param->{id}'")}; 
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

true;
