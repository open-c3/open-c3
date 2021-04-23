package api::smallapplication;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;

#id
#jobid
#type
#title
#describe
#parameter
#create_user
#edit_user
#edit_time
#
get '/smallapplication' => sub {
    my @col = qw( id jobid type title describe parameter create_user edit_user edit_time create_time );
    my $r = eval{ $api::mysql->query( sprintf( "select %s from smallapplication order by id", join( ',', map{"`$_`"}@col) ), \@col )};
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

get '/smallapplication/:id' => sub {
    my $param = params();
    my $error = Format->new( id => qr/^\d+$/, 1,)->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my @col = qw( id jobid type title describe parameter create_user edit_user edit_time create_time );
    my $r = eval{ $api::mysql->query( sprintf( "select %s from smallapplication where id=$param->{id}", join( ',', @col) ), \@col )};
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0] };
};

post '/smallapplication' => sub {
    my $param = params();
    my $error = Format->new( 
        jobid => qr/^\d+$/, 1,
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
            "insert into smallapplication (`jobid`,`type`,`title`,`describe`,`parameter`,`create_user`,`edit_user`,`edit_time`)
                 values('$param->{jobid}', '$param->{type}', '$param->{title}', '$param->{describe}', '$param->{parameter}', '$user', '$user', '$time')")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

post '/smallapplication/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
        jobid => qr/^\d+$/, 1,
        type => [ 'mismatch', qr/'/ ], 1,
        title => [ 'mismatch', qr/'/ ], 1,
        describe => [ 'mismatch', qr/'/ ], 1,
        parameter => [ 'mismatch', qr/'/ ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $smallapplicationname = eval{ $api::mysql->query( "select name from smallapplication where id='$param->{id}'")};
    eval{ $api::auditlog->run( user => $user, title => 'EDIT SMALLAPPLICATION', content => "NAME:$smallapplicationname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( "update smallapplication set `jobid`='$param->{jobid}',`type`='$param->{type}',`title`='$param->{title}',`describe`='$param->{describe}',`parameter`='$param->{parameter}',edit_user='$user',edit_time='$time' where id='$param->{id}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

del '/smallapplication/:id' => sub {
    my $param = params();
    my $error = Format->new( id => qr/^\d+$/, 1,)->check( %$param ); 
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $smallapplicationname = eval{ $api::mysql->query( "select name from smallapplication where id='$param->{id}'")};
    eval{ $api::auditlog->run( user => $user, title => 'DELETE SMALLAPPLICATION', content => "NAME:$smallapplicationname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ $api::mysql->execute( "delete from smallapplication where id='$param->{id}'")}; 
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

true;
