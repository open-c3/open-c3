package api::monitor::ack;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

get '/monitor/ack/myack/bycookie' => sub {
    my $param = params();

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my @col = qw(
        openc3_monitor_ack_table.id
        openc3_monitor_ack_table.caseuuid
        openc3_monitor_ack_table.labels
        openc3_monitor_ack_table.ackuuid

        openc3_monitor_ack_active.uuid
        openc3_monitor_ack_active.type
        openc3_monitor_ack_active.expire
        openc3_monitor_ack_active.edit_user
        openc3_monitor_ack_active.edit_time
    );
    my $time = time;
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_ack_active left join openc3_monitor_ack_table on openc3_monitor_ack_active.ackuuid=openc3_monitor_ack_table.ackuuid where (  openc3_monitor_ack_active.edit_user='$user' or openc3_monitor_ack_active.edit_user='$user/email' or openc3_monitor_ack_active.edit_user='$user/phone') and expire > $time", join( ',', @col)), \@col )};

    my @res;
    for my $x ( @$r )
    {
        my %x;
        for my $k ( keys %$x )
        {
            my $alias = $k; $alias =~ s/^[^.]+\.//;
            $x{$alias} = $x->{$k};
        }
        $x{expirem} = 1 + int (( $x{expire} - time )/ 60 );
        $x{mt     } = $x{uuid} =~ /\./ ? "Case" : "Strategy";
        $x{to     } = $x{type} eq 'P' ? "Personal" : "All";
        push @res, \%x;
    }
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@res };
};

post '/monitor/ack/myack/bycookie' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::mysql->execute( "update openc3_monitor_ack_active set expire=0 where  ( edit_user='$user' or edit_user='$user/email' or edit_user='$user/phone') and ackuuid='$param->{uuid}'" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

get '/monitor/ack/allack/bycookie' => sub {
    my $param = params();

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my @col = qw(
        openc3_monitor_ack_table.id
        openc3_monitor_ack_table.caseuuid
        openc3_monitor_ack_table.labels
        openc3_monitor_ack_table.ackuuid

        openc3_monitor_ack_active.uuid
        openc3_monitor_ack_active.type
        openc3_monitor_ack_active.expire
        openc3_monitor_ack_active.edit_user
        openc3_monitor_ack_active.edit_time
    );
    my $time = time;
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_ack_active left join openc3_monitor_ack_table on openc3_monitor_ack_active.ackuuid=openc3_monitor_ack_table.ackuuid where expire > $time", join( ',', @col)), \@col )};

    my @res;
    for my $x ( @$r )
    {
        my %x;
        for my $k ( keys %$x )
        {
            my $alias = $k; $alias =~ s/^[^.]+\.//;
            $x{$alias} = $x->{$k};
        }
        $x{expirem} = 1 + int (( $x{expire} - time )/ 60 );
        $x{mt     } = $x{uuid} =~ /\./ ? "Case" : "Strategy";
        $x{to     } = $x{type} eq 'P' ? "Personal" : "All";
        push @res, \%x;
    }
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@res };
};

post '/monitor/ack/allack/bycookie' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;
 
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::mysql->execute( "update openc3_monitor_ack_active set expire=0 where ackuuid='$param->{uuid}'" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};


get '/monitor/ack/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $uuid, $usertoken ) = ( substr( $param->{uuid}, 0, 12 ), substr( $param->{uuid}, 12 ) );
    my $user = `c3mc-base-user-temp-token  -get '$usertoken'`;
    chomp $user;
    return  +{ stat => $JSON::false, info => "check format fail $error" } unless $user && $user =~ /^[a-zA-Z0-9][a-zA-Z0-9@\.\-_\/]+[a-zA-Z0-9]$/;
    my $u = ( split /\//, $user )[0];

    my @col = qw( id labels fingerprint caseuuid );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_ack_table where ackuuid='$uuid'", join( ',', @col)), \@col )};

    my ( $acked, $time, @res ) = ( 0, time );
    my %acked = map{ $_ => 0 }qw( ackP ackG ackcaseP ackcaseG ackam );
    my $amackid = 0;
    for my $x ( @$r )
    {
        $amackid = $x->{id};
        map{
            my @x = split /=/, $_, 2;
            push @res, +{ name => $x[0], value => $x[1] }
        } split /,/, $x->{labels};

        my $xx = eval{ 
            $api::mysql->query( "select type,uuid,edit_user from openc3_monitor_ack_active where ( uuid='$x->{fingerprint}' or uuid='$x->{caseuuid}' ) and expire>$time" ) };
        for( @$xx )
        {
            my ( $type, $uuid, $edit_user ) = @$_;
            my $bt = $uuid =~ /\./ ? 'ackcase' : 'ack';
            my $ut = ( split /\//, $edit_user )[0];
            if( $type eq 'P' )
            {
                $acked{ $bt. $type } = 1 if $u eq  $ut;
            }
            else
            {
                $acked{ $bt. $type } = 1;
            }
        }
    }

    my $info = `amtool --alertmanager.url=http://openc3-alertmanager:9093 silence`;
    $acked{ackam} = $info =~ m#by-c3-ack-\($amackid\)# ? 1 : 0;
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@res, acked => \%acked };
};

post '/monitor/ack/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
        ctrl => [ 'in', 'ack', 'ackcase', 'ackam' ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $u, $ctrl ) = @$param{qw( uuid ctrl )};
    my ( $uuid, $usertoken ) = ( substr( $u, 0, 12 ), substr( $u, 12 ) );
    my $user = `c3mc-base-user-temp-token  -get '$usertoken'`;
    chomp $user;
    return  +{ stat => $JSON::false, info => "check format fail $error" } unless $user && $user =~ /^[a-zA-Z0-9][a-zA-Z0-9@\.\-_\/]+[a-zA-Z0-9]$/;

    my $time = time + 86400;
    my $type = $param->{type} && $param->{type} eq 'P' ? 'P' : 'G';

    if( $type eq 'G' && $ctrl ne 'ackam' )
    {
        my $u = (split /\//, $user )[0];
        my @auth = `c3mc-base-db-get name -t openc3_connector_userauth --filter "name='$u' and level >=2"`;
        return  +{ stat => $JSON::false, info => "no auth" } unless @auth;
    }

    if( $ctrl eq 'ackam' )
    {
        my $u = (split /\//, $user )[0];
        my @auth = `c3mc-base-db-get name -t openc3_connector_userauth --filter "name='$u' and level >=3"`;
        return  +{ stat => $JSON::false, info => "no auth" } unless @auth;
    }

    eval{
        if( $ctrl eq 'ackcase' )
        {
            $api::mysql->execute( "insert into openc3_monitor_ack_active ( uuid,type,treeid,edit_user,expire,ackuuid ) select `caseuuid`,'$type',treeid,'$user','$time','$uuid' from openc3_monitor_ack_table  where ackuuid='$uuid'" );
        }
        elsif( $ctrl eq 'ackam' )
        {
            my $x = $api::mysql->query( "select labels,id from openc3_monitor_ack_table where ackuuid='$uuid'" );
            die "nofind your ackuuid" unless $x && @$x > 0;
            my @x;
            for( split /,/, $x->[0][0] )
            {
                next if $_ =~ /'/;
                my @xx = split /=/, $_, 2;
                push @x, "$1=$xx[1]" if $xx[0] =~ /^labels\.(.+)$/;
            }
            
            system( sprintf "c3mc-mon-alertmanager-silence -c 'by-c3-ack-($x->[0][1])' -u '$user' %s", join ' ', map{ "'$_'" }@x  ) if @x;
        }
        else
        {
            $api::mysql->execute( "insert into openc3_monitor_ack_active ( uuid,type,treeid,edit_user,expire,ackuuid ) select `fingerprint`,'$type',treeid,'$user','$time','$uuid' from openc3_monitor_ack_table  where ackuuid='$uuid'" );
        }
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
