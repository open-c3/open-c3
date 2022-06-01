package api::adminapproval;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;
use Util;

get '/adminapproval' => sub {
    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my @col = qw( id taskuuid name opinion remarks create_time finishtime submitter oauuid notifystatus user assist );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_approval order by id desc limit 100", join( ',', @col ) ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => $r };
};

post '/adminapproval' => sub {
    my $param = params();
    my $error = Format->new( 
        opinion => [ 'in', 'agree', 'refuse' ], 1,
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'USR APPROVAL', content => "ID:$param->{id} OPINION:$param->{opinion}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $time = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $r = eval{ $api::mysql->execute( "update openc3_job_approval set opinion='$param->{opinion}',finishtime='$time',assist='$user' where id='$param->{id}' and opinion='unconfirmed'")};

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

get '/adminapproval/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my @col = qw( id taskuuid name cont opinion remarks create_time finishtime submitter oauuid notifystatus user assist );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_job_approval
                where taskuuid in ( select taskuuid from openc3_job_approval where id='$param->{id}')", join( ',', @col ) ), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => $r };
};

get '/adminapproval/oalog/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    my $path = "/data/open-c3-data/glusterfs/approval_log";

    my %data;
    for my $x ( qw( create query ) )
    {
        $data{$x} = +{ log => 'NULL', time => 'NULL' };
        my $f = "$path/$x.$param->{id}";
        next unless -f $f;
        $data{$x}{time} = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime( ( stat $f )[9] ) );
        $data{$x}{log } = `cat '$f' 2>&1`;
    }
    return +{
        stat => $JSON::true,
        data => \%data,
    };
};

post '/adminapproval/oaredo/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'USR APPROVAL OA REDO', content => "ID:$param->{id}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ $api::mysql->execute( "update openc3_job_approval set oauuid='0' where id='$param->{id}' and opinion='unconfirmed'")};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => $r };
};

post '/adminapproval/notifyredo/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_job_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'USR APPROVAL NOTIFY REDO', content => "ID:$param->{id}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ $api::mysql->execute( "update openc3_job_approval set notifystatus='null' where id='$param->{id}' and opinion='unconfirmed'")};

    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => $r };
};

true;
