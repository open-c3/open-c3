package api::monitor::config::mailmon;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

my $path = "/data/glusterfs/mailmon";

get '/monitor/config/mailmon' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;

    my @col = qw( id name description edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_mailmon", join( ',', map{ "`$_`" }@col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

get '/monitor/config/mailmon/history' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;

    my @col = qw( id account severity subject content date from create_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_history_mailmon", join( ',', map{ "`$_`" }@col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

get '/monitor/config/mailmon/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;

    my @col = qw( id name description edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_mailmon where id='$param->{id}'", join( ',', @col)), \@col )};

    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{
        my %user;
        my $file = "$path/conf/$r->[0]{name}";
        my @c = YAML::XS::LoadFile $file;
        $r->[0]{config} =  `cat '$file'`;
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r->[0] };
};

post '/monitor/config/mailmon' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 0,
        name => qr/^[a-zA-Z][a-zA-Z0-9\.\-_]*$/, 1,
        description => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my ( $id, $name, $description, $config ) = @$param{qw( id name description config )};
    eval{ YAML::XS::Load $config; };
    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{
        my $title = $id ? "UPDATE" : "ADD";
        $api::auditlog->run( user => $user, title => "$title MONITOR CONFIG MAILMON", content => "NAME:$name DESCRIPTION:$description" );
        if( $param->{id} )
        {
            $api::mysql->execute( "update openc3_monitor_config_mailmon set `name`='$name',description='$description' where id='$id'" );
        }
        else
        {
            $api::mysql->execute( "insert into openc3_monitor_config_mailmon (`name`,`description`,`edit_user`) values('$name','$description','$user')" );
        }
    };

    return +{ stat => $JSON::false, info => $@ } if $@;

    eval{
        my $tmp = File::Temp->new( SUFFIX => ".mailmon", UNLINK => 0 );
        print $tmp $config;
        close $tmp;
        system sprintf "mv '%s' '$path/conf/$name'",$tmp->filename;

    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

del '/monitor/config/mailmon/:id' => sub {
    my $param = params();
    my $error = Format->new( 
        id => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    my $cont = eval{ $api::mysql->query( "select `name`,`description` from openc3_monitor_config_mailmon where id='$param->{id}'")};
    my $c = $cont->[0];
    eval{ $api::auditlog->run( user => $user, title => 'DEL MONITOR CONFIG MAILMON', content => "NAME:$c->[0] DESCRIPTION:$c->[1]" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    map{
        my $file = "$path/$_/$c->[0]";
        if( -f $file )
        {
            unlink $file or return +{ stat => $JSON::false, info => "unlink file: $!" };
        }
    }qw( conf data );

    my $r = eval{ 
        $api::mysql->execute(
            "delete from openc3_monitor_config_mailmon where id='$param->{id}'")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
