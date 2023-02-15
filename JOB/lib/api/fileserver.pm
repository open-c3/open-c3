package api::fileserver;
use Dancer ':syntax';
use Dancer qw(cookie);
use FindBin qw( $RealBin );
use Encode;
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Digest::MD5;
use Format;
use Util;
use LWP::UserAgent;
use Logs;

my $logs = Logs->new( 'job_api_fileserver' );

get '/fileserver/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id name size md5 create_user create_time edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_fileserver
                where projectid='$param->{projectid}' and status='available' order by id", join ',', @col ), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

post '/fileserver/:projectid' => sub {
    my $param = params();

    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $upload = request->uploads;
    return  +{ stat => $JSON::false, info => 'upload undef' } unless $upload && ref $upload eq 'HASH';

    my $path = "$RealBin/../fileserver/$param->{projectid}";
    mkdir $path unless -d $path;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    for my $info ( values %$upload )
    {
        $error = Format->new( 
            filename => [ 'mismatch', qr/'/ ], 1,
            tempname => [ 'mismatch', qr/'/ ], 1,
            size => qr/^\d+$/, 1,
        )->check( %$info );
        return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

        my ( $filename, $tempname, $size ) = @$info{qw( filename tempname size )};

        eval{ $api::auditlog->run( user => $user, title => 'USER UPLOAD FILE', content => "TREEID:$param->{projectid} FILENAME:$filename" ); };
        return +{ stat => $JSON::false, info => $@ } if $@;

        open my $fh, "<$tempname" or return +{ stat => $JSON::false, info => 'open file fail' };
        my $md5 = Digest::MD5->new()->addfile( $fh )->hexdigest;
        close $fh;

        return  +{ stat => $JSON::false, info => 'rename fail' } if system "mv '$tempname' '$path/$md5' && chmod a+r '$path/$md5'";

        my $r = eval{ 
            $api::mysql->execute( 
                "replace into openc3_job_fileserver (`projectid`,`name`,`size`,`md5`,`create_user`,`create_time`,`edit_user`,`edit_time`,`status`)
                    values( '$param->{projectid}', '$filename','$size', '$md5', '$user','$time', '$user', '$time','available' )")};
    
        return +{ stat => $JSON::false, info => $@ } if $@;
    }

    return  +{ stat => $JSON::true, data => scalar keys %$upload };
};

get '/fileserver/:projectid/download' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1, name => [ 'mismatch', qr/'/ ], 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id name size md5 create_user create_time edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_fileserver
                where projectid='$param->{projectid}' and status='available' and name='$param->{name}'", join ',', @col ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::false, info => "notfind the file" } unless @$r;

    my $path = "$RealBin/../fileserver/$param->{projectid}";
    my $name;

    if( $param->{name} =~ /^([a-zA-Z0-9:\@_\-\.]+)(\.[a-zA-Z0-9]+)$/ )
    {
        $name = sprintf "$1.%s$2", uuid->new()->create_str;
    }
    else
    {
        my $suffix = '';
        $suffix = $1 if $param->{name} =~ /(\.[a-zA-z0-9]+)$/;
        $name = sprintf "Download.%s.%s$suffix", POSIX::strftime( "%Y%m%d.%H%M%S", localtime ), uuid->new()->create_str;
    }

    return +{ stat => $JSON::false, info => "link fail: $!" } if system "ln -fsn '$path/$r->[0]{md5}' '$RealBin/../downloadpath/$name'";
    return +{ stat => $JSON::true, data => $name };
};

post '/fileserver/:projectid/upload' => sub {
    my $param = params();

    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    return  +{ stat => $JSON::false, info => "no token" } unless my $token = request->headers->{'token'};
    return  +{ stat => $JSON::false, info => "token format error" } unless $token =~ /^[a-zA-Z0-9]{32}$/;

    my $r = eval{ 
        $api::mysql->query( 
            "select count(*) from openc3_job_token
                where token='$token' and projectid in ( '$param->{projectid}', 0 ) and status='available'" )};
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::false, info => 'not authorized' } unless $r && $r->[0][0] > 0;

    my $upload = request->uploads;
    return  +{ stat => $JSON::false, info => 'upload undef' } unless $upload && ref $upload eq 'HASH';

    my $path = "$RealBin/../fileserver/$param->{projectid}";
    mkdir $path unless -d $path;

    my $user = substr( $token, 0, 8 ) .'@token';
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $username = $param->{'user' } && $param->{'user' } =~ /^[a-zA-Z0-9\.\-_@]+$/ ? $param->{'user' } : $user;

    my $upfilename;
    for my $info ( values %$upload )
    {
        $error = Format->new( 
            filename => [ 'mismatch', qr/'/ ], 1,
            tempname => [ 'mismatch', qr/'/ ], 1,
            size => qr/^\d+$/, 1,
        )->check( %$info );
        return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

        my ( $filename, $tempname, $size ) = @$info{qw( filename tempname size )};
        $upfilename = $filename;

        eval{ $api::auditlog->run( user => 'token', title => 'TOKEN UPLOAD FILE', content => "TREEID:$param->{projectid} FILENAME:$filename" ); };
        return +{ stat => $JSON::false, info => $@ } if $@;

        open my $fh, "<$tempname" or return +{ stat => $JSON::false, info => 'open file fail' };
        my $md5 = Digest::MD5->new()->addfile( $fh )->hexdigest;
        close $fh;

        return  +{ stat => $JSON::false, info => 'rename fail' } if system "mv '$tempname' '$path/$md5' && chmod a+r '$path/$md5'";

        my $r = eval{ 
            $api::mysql->execute( 
                "replace into openc3_job_fileserver (`projectid`,`name`,`size`,`md5`,`create_user`,`create_time`,`edit_user`,`edit_time`,`status`)
                    values( '$param->{projectid}', '$filename','$size', '$md5', '$username','$time', '$user', '$time','available' )")};
    
        return +{ stat => $JSON::false, info => $@ } if $@;
    }

    $r = eval{
        $api::mysql->query("select isjob,jobname from openc3_job_token where token='$token' and projectid=$param->{projectid} and status='available'" ) };

    return +{ stat => $JSON::false, info => "upload file success, query job fail $@" } if $@;
    return +{ stat => $JSON::false, info => "upload file success, query job fail, get data error from db" } unless defined $r && ref $r eq 'ARRAY';
    my $isjob = $r->[0][0];
    my $jobname = encode_utf8($r->[0][1]);

    if ($isjob) {
        eval {
            my $ua = LWP::UserAgent->new();
            $ua->agent('Mozilla/9 [en] (Centos; Linux)');
            my %env = eval{ Util::envinfo( qw( appkey appname envname ) )};
            return +{ stat => $JSON::false, info => "upload file success, excuete job fail ,fromat error $@" } if $@;
            $ua->default_header( map{ $_ => $env{$_} }qw( appname appkey) );
            $ua->timeout( 10 );
            $ua->default_header ( 'Cache-control' => 'no-cache', 'Pragma' => 'no-cache' );

            my $url = "http://api.job.open-c3.org/task/$param->{projectid}/job/byname";
            my $res = $ua->post( $url,
            Content => JSON::to_json( +{ jobname => $jobname, variable => +{ version => $upfilename} } ),
            'Content-Type' => 'application/json'
            );

            my $cont = $res->content;
            return +{ stat => $JSON::false, info => "upload file success, excuete job fail,calljob fail: $cont" } unless $res->is_success;

            my $data = eval{JSON::from_json $cont};
        };
        return +{ stat => $JSON::false, info => "upload file success, excuete job fail $@" } if $@;
    }

    return  +{ stat => $JSON::true, data => scalar keys %$upload };
};

del '/fileserver/:projectid/:fileserverid' => sub {
    my $param = params();

    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        fileserverid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_delete', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $t    = Util::deleteSuffix();

    my $filename = eval{ $api::mysql->query( "select name from openc3_job_fileserver where id='$param->{fileserverid}'")};
    eval{ $api::auditlog->run( user => $user, title => 'DELETE FILE', content => "TREEID:$param->{projectid} FILENAME:$filename->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "update openc3_job_fileserver set status='deleted',name=concat(name,'_$t'),edit_user='$user',edit_time='$time' 
                where id='$param->{fileserverid}' and projectid='$param->{projectid}' and status='available'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

true;
