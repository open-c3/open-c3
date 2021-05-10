package api::project;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;

get '/project/:groupid/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', $param->{groupid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $relation = $param->{relation} ? ", '0'" : '';
    my @col = qw( id status autobuild name excuteflow calljobx calljob
        webhook webhook_password webhook_release rely buildimage buildscripts
        follow_up follow_up_ticketid callback groupid addr notify
        edit_user edit_time  slave last_findtags last_findtags_success 
        ticketid tag_regex autofindtags callonlineenv calltestenv findtags_at_once );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_ci_project where id='$projectid'", join( ',', @col)), \@col )};

    my $data = $r && @$r ? $r->[0] : +{};

    map{ 
        $data->{$_}  = decode_base64( $data->{$_}  ) if defined $data->{$_}
    }qw( buildscripts webhook_password password );

    map{
        $data->{$_}  = Encode::decode("utf8", $data->{$_}) if defined $data->{$_}
    }qw( buildscripts );

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $data  };
};

post '/project/:groupid/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        status => qr/^\d+$/, 1,
        autobuild => qr/^\d+$/, 1,
        name => [ 'mismatch', qr/'/ ], 0,
        excuteflow => [ 'mismatch', qr/'/ ], 0,
        calljobx => [ 'mismatch', qr/'/ ], 0,
        calljob => [ 'mismatch', qr/'/ ], 0,
        webhook => qr/^\d+$/, 1,
        webhook_password => [ 'mismatch', qr/'/ ], 0,
        webhook_release => [ 'mismatch', qr/'/ ], 0,
        rely => qr/^\d+$/, 1,
        buildimage => [ 'mismatch', qr/'/ ], 0,
        follow_up => [ 'mismatch', qr/'/ ], 0,
        follow_ucallback => [ 'mismatch', qr/'/ ], 0,
        groupid => qr/^\d+$/, 1,
        addr => [ 'mismatch', qr/'/ ], 1,
        username => [ 'mismatch', qr/'/ ], 0,
        password => [ 'mismatch', qr/'/ ], 0,
        notify => [ 'mismatch', qr/'/ ], 0,
        tag_regex => [ 'mismatch', qr/'/ ], 0,
        autofindtags => qr/^\d+$/, 1,
        callonlineenv => qr/^\d+$/, 1,
        calltestenv => qr/^\d+$/, 1,
        ticketid => qr/^\d*$/, 0,
        follow_up_ticketid => qr/^\d*$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_write', $param->{groupid} ); return $pmscheck if $pmscheck;

    map{ 
        $param->{$_}  = encode_base64( encode('UTF-8',  $param->{$_}) );
    }qw( buildscripts webhook_password password );

    my $projectid = $param->{projectid};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'EDIT FLOWLINE CI', content => "TREEID:$param->{groupid} FLOWLINEID:$projectid NAME:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my @col = qw( 
        status autobuild name excuteflow calljobx calljob
        webhook webhook_password webhook_release rely buildimage buildscripts
        follow_up follow_up_ticketid callback groupid addr
        notify ticketid tag_regex autofindtags callonlineenv calltestenv
    );
    eval{ 
        $api::mysql->execute(
            sprintf "replace into openc3_ci_project (`id`,`edit_user`,%s ) values( '$projectid','$user', %s )", 
            join(',',map{"`$_`"}@col), join(',',map{"'$param->{$_}'"}@col)
        );
    };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

del '/project/:groupid/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        groupid => qr/^\d+$/, 1,
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_delete', $param->{groupid} ); return $pmscheck if $pmscheck;

    my ( $groupid, $projectid ) = @$param{qw( groupid projectid )};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ),
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $flowname = eval{ $api::mysql->query( "select name from openc3_ci_project where groupid='$groupid' and id='$projectid'" )}; 
    eval{ $api::auditlog->run( user => $user, title => 'DELETE FLOWLINE', content => "TREEID:$groupid FLOWLINEID:$projectid NAME:$flowname->[0][0]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute( "delete from openc3_ci_rely where projectid='$projectid'" );
        $api::mysql->execute( "delete from openc3_ci_project where groupid='$groupid' and id='$projectid'" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \$r };
};

put '/project/:groupid/:projectid/findtags_at_once' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_ci_control', $param->{groupid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'FIND TAGS', content => "TREEID:$param->{groupid} FLOWLINEID:$param->{projectid}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{ 
        $api::mysql->execute( "update openc3_ci_project set findtags_at_once=1 where id=$param->{projectid}" ); 
    };

    return $@ ?  +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
