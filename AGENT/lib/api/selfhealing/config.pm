package api::selfhealing::config;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

get '/selfhealing/config' => sub {
    my $param = params();

    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;

    my @col = qw( id name altername jobname edit_user edit_time eips );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_self_healing_config", join( ',', map{ "`$_`" }@col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

get '/selfhealing/config/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( id name altername jobname edit_user edit_time eips );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_self_healing_config where id='$param->{id}'", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0] };
};

post '/selfhealing/config' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 0,
        name => [ 'mismatch', qr/'/ ], 1,
        altername => [ 'mismatch', qr/'/ ], 1,
        jobname => [ 'mismatch', qr/'/ ], 1,
        eips => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my ( $id, $name, $altername, $jobname, $eips ) = @$param{qw( id name altername jobname eips )};
    $eips ||= '';

    eval{
        my $title = $id ? "UPDATE" : "ADD";
        $api::auditlog->run( user => $user, title => "$title SELFHEALING CONFIG", content => "NAME:$name ALTERNAME:$altername JOBNAME:$jobname" );
        if( $id )
        {
            $api::mysql->execute( "update openc3_monitor_self_healing_config set `name`='$name',`altername`='$altername',`jobname`='$jobname',`eips`='$eips' where id='$id'" );
        }
        else
        {
            $api::mysql->execute( "insert into openc3_monitor_self_healing_config (`name`,`altername`,`jobname`,`eips`) values('$name','$altername','$jobname','$eips')" );
        }
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

del '/selfhealing/config/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_delete', 0 ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $cont = eval{ $api::mysql->query( "select `name`,`altername`,`jobname` from openc3_monitor_self_healing_config where id='$param->{id}'")};
    my $c = $cont->[0];
    eval{ $api::auditlog->run( user => $user, title => 'DEL SELFHEALING CONFIG', content => "NAME:$c->[0] ALTERNAME:$c->[1] JOBNAME:$c->[2]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "delete from openc3_monitor_self_healing_config where id='$param->{id}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
