package api::check;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Format;

=pod

AGENT/自动检查/获取开关状态

=cut

get '/check/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( status last_check last_check_s last_success last_success_s slave );
    my $r = eval{ 
        $api::mysql->query( 
            "select status,last_check,UNIX_TIMESTAMP(last_check),last_success,UNIX_TIMESTAMP(last_success),slave from `openc3_agent_check` where projectid='$projectid'", \@col )};

    my $data =  ($r && @$r ) ? $r->[0] : +{ status => 'off' };
    $data->{last_check_x} = ($data->{last_check_s} + 600 > time ) ? 0 : 1 if $data->{last_check_s};
    $data->{last_success_x} = ($data->{last_success_s} + 600 > $data->{last_check_s}  ) ? 0 : 1 if $data->{last_check_s} && $data->{last_success_s};
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $data };
};

=pod

AGENT/自动检查/修改开关状态

=cut

post '/check/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        status => qr/^[a-z]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{projectid} ); return $pmscheck if $pmscheck;

    my ( $projectid, $status ) = @$param{qw( projectid status )};
    $status = 'off' if $status ne 'on';
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => 'AGENT CHECK', content => "TREEID:$projectid STATUS:$status" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( "replace into `openc3_agent_check` (`projectid`,`status`,`user`) values( '$projectid', '$status','$user' )");
    };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};


true;
