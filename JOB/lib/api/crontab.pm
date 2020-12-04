package api::crontab;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;
use Util;
use Crontab;

#name
#create_user
#edit_user
#create_time_start
#create_time_end
#edit_time_start
#edit_time_end
get '/crontab/:projectid' => sub {
    my $param = params();

    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 0,
        create_user => [ 'mismatch', qr/'/ ], 0,
        edit_user => [ 'mismatch', qr/'/ ], 0,
        create_time_start => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        create_time_end => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        edit_time_start => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        create_time_end => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @where;
    push @where, "name like '%$param->{name}%'" if defined $param->{name};

    map{ push @where, "$_='$param->{$_}'" if defined $param->{$_} }qw( create_user edit_user );

    my %type = ( start => '>=', end => '<=' );
    my %time = ( start => '00:00:00', end => '23:59:59');

    for my $type ( keys %type )
    {
        for my $g ( qw( create_time edit_time ) )
        {
            my $grep = "${g}_$type";
            push @where, "$g $type{$type} '$param->{$grep} $time{$type}'" if defined $param->{$grep};
        }
    }

    my @col = qw( id name jobuuid cron mutex status create_user create_time edit_user edit_time );

    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from crontab
                where status<>'deleted' and jobuuid in ( select uuid from jobs where projectid='$param->{projectid}' ) %s", 
                join( ',', @col ),@where? ' and '.join( ' and ', @where ):'' ), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

get '/crontab/:projectid/count' => sub {
    my $param = params();

    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select status,count(*) from crontab
                where status<>'deleted' and jobuuid in
                ( select uuid from jobs where projectid='$param->{projectid}' ) group by status" ) )};

    my %data = map{ @$_ }@$r;
    map{ $data{$_}||= 0 }qw( available unavailable );

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \%data };
};


get '/crontab/:projectid/:crontabid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        crontabid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id name jobuuid cron mutex status create_user create_time edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from crontab
                where id='$param->{crontabid}' and status<>'deleted' and jobuuid in 
                    ( select uuid from jobs where projectid='$param->{projectid}' )", join ',', @col ), \@col )};

    my %x = %{$r->[0]};
    $x{cont} = decode_base64( $x{cont} );

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \%x };
};

#name
#jobuuid
#cron
#mutex  ?
post '/crontab/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1,
        cron => qr/^[\*0-9\-,\/]+\s+[\*0-9\-,\/]+\s+[\*0-9\-,\/]+\s+[\*0-9\-,\/]+\s+[\*0-9\-,\/]+$/, 1,
        mutex => qr/^[a-zA-Z0-9]*$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $cronformaterr = Crontab->new( $param->{cron} )->format();
    return  +{ stat => $JSON::false, info => "crontab $cronformaterr" } if $cronformaterr;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    $param->{mutex} ||='';

    my $m = eval{ $api::mysql->query( "select count(*) from jobs
            where projectid='$param->{projectid}' and uuid='$param->{jobuuid}' " );};

    return  +{ stat => $JSON::false, info => $@ } if $@;
    return  +{ stat => $JSON::false, info => "jobuuid $param->{jobuuid} not in the project $param->{projectid}" } 
        unless $m && $m->[0][0] eq 1;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ));
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $r = eval{ 
        $api::mysql->execute( 
            "insert into crontab (`name`,`jobuuid`,`cron`,`mutex`,`create_user`,`create_time`,`edit_user`,`edit_time`,`status`)
                values( '$param->{name}','$param->{jobuuid}', '$param->{cron}','$param->{mutex}', '$user','$time', '$user', '$time','unavailable' )")};

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

#name
#jobuuid
#cron
#mutex  ?
post '/crontab/:projectid/:crontabid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        crontabid => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 1,
        jobuuid => qr/^[a-zA-Z0-9]+$/, 1,
        cron => qr/^[\*0-9\-,\/]+\s+[\*0-9\-,\/]+\s+[\*0-9\-,\/]+\s+[\*0-9\-,\/]+\s+[\*0-9\-,\/]+$/, 1,
        mutex => qr/^[a-zA-Z0-9]*$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $cronformaterr = Crontab->new( $param->{cron} )->format();
    return  +{ stat => $JSON::false, info => "crontab $cronformaterr" } if $cronformaterr;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    $param->{mutex} ||='';

    my $m = eval{ $api::mysql->query( "select count(*) from jobs
            where projectid='$param->{projectid}' and uuid='$param->{jobuuid}' " );};

    return  +{ stat => $JSON::false, info => $@ } if $@;
    return  +{ stat => $JSON::false, info => "jobuuid $param->{jobuuid} not in the project $param->{projectid}" } 
        unless $m && $m->[0][0] eq 1;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ));
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $r = eval{ 
        $api::mysql->execute( 
            "update crontab set name='$param->{name}',jobuuid='$param->{jobuuid}',
                cron='$param->{cron}',mutex='$param->{mutex}',edit_user='$user',edit_time='$time'
                    where id='$param->{crontabid}' and status<>'deleted' and jobuuid
                        in ( select uuid from jobs where projectid='$param->{projectid}')")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

#status
post '/crontab/:projectid/:crontabid/status' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        crontabid => qr/^\d+$/, 1,
        status => [ 'in', 'available', 'unavailable' ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ));
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $m = eval{ $api::mysql->query( "select count(*) from jobs,crontab where 
            crontab.jobuuid=jobs.uuid and jobs.projectid='$param->{projectid}' and crontab.id='$param->{crontabid}'" );};

    return  +{ stat => $JSON::false, info => $@ } if $@;
    return  +{ stat => $JSON::false, info => "crontabid $param->{crontabid} not belong project $param->{projectid}" } 
        unless $m && $m->[0][0] eq 1;


    my $r = eval{ 
        $api::mysql->execute( 
            "update crontab set status='$param->{status}',edit_user='$user',edit_time='$time'
                where id='$param->{crontabid}' and status<>'deleted' and jobuuid 
                    in ( select uuid from jobs where projectid='$param->{projectid}')")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

del '/crontab/:projectid/:crontabid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        crontabid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $m = eval{ $api::mysql->query( "select count(*) from jobs,crontab where 
            crontab.jobuuid=jobs.uuid and jobs.projectid='$param->{projectid}' and crontab.id='$param->{crontabid}'" );};

    return  +{ stat => $JSON::false, info => $@ } if $@;
    return  +{ stat => $JSON::false, info => "crontabid $param->{crontabid} not belong project $param->{projectid}" } 
        unless $m && $m->[0][0] eq 1;


    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ));
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $t    = Util::deleteSuffix();

    my $r = eval{ 
        $api::mysql->execute(
            "update crontab set status='deleted',name=concat(name,'_$t'),edit_user='$user',edit_time='$time' 
                where id='$param->{crontabid}' and status<>'deleted' and jobuuid 
                    in ( select uuid from jobs where projectid='$param->{projectid}')")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

true;
