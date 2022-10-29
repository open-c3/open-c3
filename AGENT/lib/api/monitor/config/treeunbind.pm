package api::monitor::config::treeunbind;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

get '/monitor/config/treeunbind' => sub {
    my $param = params();

    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;

    my    @treemap = `c3mc-base-treemap`;
    chomp @treemap;
    my    %treemap;
    map{
        my @x = split /;/, $_, 2;
        $treemap{$x[0]} = $x[1] if @x == 2;
    } @treemap;

    my @col = qw( id treeid status edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_treeunbind where status=1", join( ',', map{ "`$_`" }@col)),
            \@col )
    };

    return $@ ?
        +{ stat => $JSON::false, info => $@ }
      : +{ stat => $JSON::true,  data => [ map{ +{ %$_, treename => $treemap{ $_->{treeid} } } } @$r ] };
};

get '/monitor/config/treeunbind/:treeid' => sub {
    my $param = params();
    my $error = Format->new( 
        treeid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{treeid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my @col = qw( id treeid status edit_user edit_time );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_config_treeunbind where treeid='$param->{treeid}'", join( ',', @col)),
            \@col )
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => @$r ? $r->[0] : +{} };
};

post '/monitor/config/treeunbind/:treeid' => sub {
    my $param = params();
    my $error = Format->new( 
        treeid => qr/^\d+$/, 1,
        status => qr/^\d+$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_write', $param->{treeid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $status = $param->{status} ? 1 : 0;
    eval{ $api::auditlog->run( user => $user, title => "MONITOR CONFIG TREE UNBIND $status", content => "TREEID:$param->{treeid}"); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $r = eval{ 
        $api::mysql->execute(
            "replace openc3_monitor_config_treeunbind ( `treeid`,`status`,`edit_user` ) value( '$param->{treeid}', '$status', '$user' )")};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

true;
