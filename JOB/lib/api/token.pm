package api::token;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use Util;

=pod

文件管理/Token管理/列表查询

=cut

any '/token/:projectid/info' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        create_user => [ 'mismatch', qr/'/ ], 0,
        edit_user => [ 'mismatch', qr/'/ ], 0,
        create_time_start => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
        create_time_end => qr/^\d{4}\-\d{2}\-\d{2}$/, 0,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @where;
    map{ push @where, "$_='$param->{$_}'" if defined $param->{$_}; }qw( create_user edit_user );

    my %type = ( start => '>=', end => '<=' );
    my %time = ( start => '00:00:00', end => '23:59:59');
    for my $type ( keys %type )
    {
        for my $g ( qw( create_time ) )
        {
            my $grep = "${g}_$type";
            push @where, "$g $type{$type} '$param->{$grep} $time{$type}'" if defined $param->{$grep};
        }
    }

    my @col = qw( id token describe create_user create_time isjob jobname);
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_token
                where projectid='$param->{projectid}' and status='available' %s",
                    join( ',', map{"`$_`"}@col), @where ? ' and '.join( ' and ',@where ):'' ), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r || []};
};

=pod

文件管理/Token管理/创建Token

=cut

post '/token/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        token => qr/^[a-zA-Z0-9\-_\.]+$/, 1,
        describe => [ 'mismatch', qr/'/ ], 1,
        isjob => [ 'mismatch', qr/'/ ], 1,
        jobname => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    eval{ $api::auditlog->run( user => $user, title => 'ADD FILESERVER TOKEN', content => "TREEID:$param->{projectid} NAME:$param->{describe}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( 
            "insert into openc3_job_token (`projectid`,`token`,`describe`,`isjob`,`jobname`,`create_user`,`create_time`,`edit_user`,`edit_time`,`status`)
                values( '$param->{projectid}', '$param->{token}', '$param->{describe}', '$param->{isjob}', '$param->{jobname}', '$user','$time', '$user', '$time','available' )")};

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

=pod

文件管理/Token管理/删除Token

=cut

del '/token/:projectid/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $t    = Util::deleteSuffix();

    my $tokenname = eval{ $api::mysql->query( "select `describe` from openc3_job_token where id='$param->{id}'")};
    eval{ $api::auditlog->run( user => $user, title => 'DEL FILESERVER TOKEN', content => "TREEID:$param->{projectid} NAME:$tokenname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "update openc3_job_token set status='deleted',token=concat(token,'_$t'),edit_user='$user',edit_time='$time' 
                where id='$param->{id}' and projectid='$param->{projectid}' and status='available'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

true;
