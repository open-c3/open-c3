package api::project;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

get '/project/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id status edit_user edit_time );
    my $r = eval{
        $api::mysql->query(
            sprintf( "select %s from openc3_job_project
                where id='$param->{projectid}'", join ',', @col ), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } 
        : +{ stat => $JSON::true, data => $r->[0]||+{status=> 'active'} };
};

#status = active,inactive
post '/project/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        status => [ 'in', 'active', 'inactive' ], 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_job_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    eval{ $api::auditlog->run( user => $user, title => 'CHANGE PROJECT STATUS', content => "TREEID:$param->{projectid} STATUS:$param->{status}" ); };

    my $r = eval{ 
        $api::mysql->execute( 
            "replace into openc3_job_project (`id`,`status`,`edit_user` ) 
                values( '$param->{projectid}', '$param->{status}','$user' ) ")
    };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
