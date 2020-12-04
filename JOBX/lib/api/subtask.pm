package api::subtask;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;

get '/subtask/:projectid/:taskuuid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        taskuuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id parent_uuid uuid nodelist nodecount starttime finishtime runtime status confirm );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from subtask
                where parent_uuid in ( select uuid from task where projectid='$param->{projectid}' and uuid='$param->{taskuuid}') order by id asc",
                    join ',',@col ), \@col )};
    return $@ ? +{ stat => $JSON::false, info => $@ } :  +{ stat => $JSON::true, data => $r };
};

get '/subtask/:projectid/:subtaskuuid/mystatus' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        subtaskuuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( id parent_uuid uuid );
    my $r = eval{ 
        $api::mysql->query(
            sprintf( "select %s from subtask where parent_uuid in ( select parent_uuid from subtask where uuid='$param->{subtaskuuid}' ) order by id",
                    join ',',@col ), \@col )};
    return +{ stat => $JSON::false, info => $@ } if $@;

    my %data = ( action => 'nofind', batches => 0, deployenv => 'nofind', submitter => 'nofind' );
    
    if( @$r > 0 )
    {
        $data{action} = $r->[0]{parent_uuid} =~ /[a-z]$/ ? 'deploy' : 'rollback';

        my $g = eval{ $api::mysql->query( "select `group`,user from task where uuid='$r->[0]{parent_uuid}'" )};
        return +{ stat => $JSON::false, info => $@ } if $@;
        return +{ stat => $JSON::false, info => 'nofind groupname' } unless @$g > 0;
        $data{deployenv} = $g->[0][0] =~ /^_ci_online_\d+_$/ ? 'online' : $g->[0][0] =~ /^_ci_test_\d+_$/ ? 'test' : 'nofind';
        $data{submitter} = $g->[0][1];
    }

    for my $idx ( 0 .. @$r -1 )
    {
        $data{batches} = $idx + 1 if $r->[$idx]{uuid} eq $param->{subtaskuuid};
    }

    return $@ ? +{ stat => $JSON::false, info => $@ } :  +{ stat => $JSON::true, data => \%data };
};

put '/subtask/:projectid/:subtaskuuid/confirm' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        subtaskuuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_jobx_control', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $r = eval{ $api::mysql->execute( "update subtask set confirm='task stop' where uuid='$param->{subtaskuuid}' and parent_uuid in (  select uuid from task where projectid='$param->{projectid}' )" );};
    return $@ ? +{ stat => $JSON::false, info => $@ } :  +{ stat => $JSON::true, data => $r };

};
true;
