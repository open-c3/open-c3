package api::monitor::ack;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;
use Digest::MD5;

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
        type => [ 'in', 'P', 'G' ], 1,
        mt   => [ 'in', 'Strategy', 'Case' ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $where = $param->{mt} eq 'Case' ? ' and uuid like "%.%"' : ' and uuid not like "%.%"';

    eval{ $api::mysql->execute( "update openc3_monitor_ack_active set expire=0 where  ( edit_user='$user' or edit_user='$user/email' or edit_user='$user/phone') and type='$param->{type}' and ackuuid='$param->{uuid}' $where" ); };
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
        type => [ 'in', 'P', 'G' ], 1,
        mt   => [ 'in', 'Strategy', 'Case' ], 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;
 
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $where = $param->{mt} eq 'Case' ? ' and uuid like "%.%"' : ' and uuid not like "%.%"';
    eval{ $api::mysql->execute( "update openc3_monitor_ack_active set expire=0 where type='$param->{type}' and ackuuid='$param->{uuid}' $where" ); };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};


get '/monitor/ack/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $uuid, $usertoken ) = ( substr( $param->{uuid}, 0, 12 ), substr( $param->{uuid}, 12 ) );

    my $user;
    if( $usertoken )
    {
        $user = `c3mc-base-user-temp-token  -get '$usertoken'`;
        chomp $user;
    }
    else
    {
        $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    }

    return  +{ stat => $JSON::false, info => "check format fail $error" } unless $user && $user =~ /^[a-zA-Z0-9][a-zA-Z0-9@\.\-_\/]+[a-zA-Z0-9]$/;
    my $u = ( split /\//, $user )[0];

    my @col = qw( id labels fingerprint caseuuid );
    my $r = eval{ 
        $api::mysql->query( 
            sprintf( "select %s from openc3_monitor_ack_table where ackuuid='$uuid'", join( ',', @col)), \@col )};

    my ( $acked, $time, @res ) = ( 0, time );
    my %acked = map{ $_ => 0 }qw( ackP ackG ackcaseP ackcaseG ackam );
    my $amackid = 0;
    my @currlabel;
    my $caseuuid = time;
    for my $x ( @$r )
    {
        $amackid = $x->{id};
        $caseuuid = $x->{caseuuid};
        map{
            my @x = split /=/, $_, 2;
            push @res, +{ name => $x[0], value => $x[1] }
        } split /,/, $x->{labels};

        my %label = map{ "labels.".$_ => 1 }qw( alertname fromtreeid instance severity );
        for( sort split /,/, $x->{labels} )
        {
            next if $_ =~ /'/;
            my @xx = split /=/, $_, 2;
            next unless $label{$xx[0]};
            delete $label{$xx[0]};
            push @currlabel, "$1=$xx[1]" if $xx[0] =~ /^labels\.(.+)$/;
        }
 
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

    my $caseinfo = +{};
    for my $x ( @$r )
    {
        my @col = qw( instance title content );
        my $xx = eval{ $api::mysql->query( sprintf( "select %s from openc3_monitor_caseinfo where caseuuid='$x->{caseuuid}'", join ',', @col), \@col ) };
        return +{ stat => $JSON::false, info => $@ } if $@;
        $caseinfo = $xx->[0] if @$xx > 0;
    }


    @currlabel = (time) unless @currlabel;
    my $md5 = Digest::MD5->new()->add( join ',', map{ Encode::encode("utf8", $_)}@currlabel )->hexdigest();
    my $info = `amtool --alertmanager.url=http://openc3-alertmanager:9093 silence`;
    $acked{ackam} = $info =~ m#by-c3-ack-\($md5\)# ? 1 : 0;

    $r = eval{ $api::mysql->query( "select type from openc3_monitor_tott where uuid='$caseuuid'" )}; 
    return +{ stat => $JSON::false, info => $@ } if $@;

    $acked{tott} = $r && @$r ? 1 : 0;
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@res, acked => \%acked, caseinfo => $caseinfo, caseuuid => $caseuuid };
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

    my $user;
    if( $usertoken )
    {
        $user = `c3mc-base-user-temp-token  -get '$usertoken'`;
        chomp $user;
    }
    else
    {
        $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    }

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
            my %label = map{ "labels.".$_ => 1 }qw( alertname fromtreeid instance severity );
            for( sort split /,/, $x->[0][0] )
            {
                next if $_ =~ /'/;
                my @xx = split /=/, $_, 2;
                next unless $label{$xx[0]};
                delete $label{$xx[0]};
                push @x, "$1=$xx[1]" if $xx[0] =~ /^labels\.(.+)$/;
            }
            
            die sprintf( "label defect:%s\n", join ',', keys %label ) if keys %label;
            my $md5 = Digest::MD5->new()->add( join ',', map{ Encode::encode("utf8", $_)}@x )->hexdigest();
            my $cmd = sprintf "c3mc-mon-alertmanager-silence -c 'by-c3-ack-($md5)' -u '$user' %s", join ' ', map{ "'$_'" }@x;
            my $xxx = `$cmd 2>&1`;
            die "alertmanager-silence err: $xxx\n" if $?;
        }
        else
        {
            $api::mysql->execute( "insert into openc3_monitor_ack_active ( uuid,type,treeid,edit_user,expire,ackuuid ) select `fingerprint`,'$type',treeid,'$user','$time','$uuid' from openc3_monitor_ack_table  where ackuuid='$uuid'" );
        }
    };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

post '/monitor/ack/tott/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        uuid => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $u, $ctrl ) = @$param{qw( uuid ctrl )};
    my ( $uuid, $usertoken ) = ( substr( $u, 0, 12 ), substr( $u, 12 ) );

    my $user;
    if( $usertoken )
    {
        $user = `c3mc-base-user-temp-token  -get '$usertoken'`;
        chomp $user;
    }
    else
    {
        $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );
    }

    return  +{ stat => $JSON::false, info => "check format fail $error" } unless $user && $user =~ /^[a-zA-Z0-9][a-zA-Z0-9@\.\-_\/]+[a-zA-Z0-9]$/;


    my @cont = ( '从监控系统转过来的工单 By '. $user  );

    my $title = '监控事件';
    if( $param->{caseinfo} )
    {
        $title = "监控事件:" . Encode::encode("utf8",$param->{caseinfo}{title} ). '['.Encode::encode("utf8",$param->{caseinfo}{instance} ). ']';

        push @cont, "监控对象:"  . Encode::encode("utf8", $param->{caseinfo}{instance} );
        push @cont, "";
        push @cont, Encode::encode("utf8", $param->{caseinfo}{content} );
    }
    else
    {
        my %casedata;
        map{ $casedata{$_->{name}} = $_->{value} }@{ $param->{casedata}};
    
        $title = "监控事件:" . Encode::encode("utf8",$casedata{'labels.alertname'} ). '['.Encode::encode("utf8",$casedata{'labels.instance'} ). ']';

        push @cont, "监控名称: " . Encode::encode("utf8", $casedata{'labels.alertname'}        );
        push @cont, "监控对象:"  . Encode::encode("utf8", $casedata{'labels.instance'}     );
        push @cont, "";
        push @cont, "概要: "     . Encode::encode("utf8", $casedata{'labels.summary'}     );
        push @cont, "详情:"      . Encode::encode("utf8", $casedata{'labels.descriptions'} );
    }

    my    $type = `c3mc-sys-ctl sys.monitor.tt.type`;
    chomp $type;
    my $ext_tt = $type ? '--ext_tt 1' : '';
    my $file;
    eval{
        my    $tmp = File::Temp->new( SUFFIX => ".tott", UNLINK => 0 );
        print $tmp join "\n", @cont;
        close $tmp;
        $file = $tmp->filename;
        $title =~ s/'//g;
        my $x = `cat '$file'|c3mc-create-ticket --title '$title' $ext_tt 2>&1`;
        die "err: $x" if $?;
        $x =~ s/\n//g;
        die "create tt fail" unless $x && $x =~ /^[A-Z][A-Z0-9]+$/;
        my $uuid = $param->{caseuuid};
        die "uuid err" unless $uuid && $uuid =~ /^[a-zA-Z0-9\.\-:]+$/;
        my $ctype = $type ? '1' : '0';
        $api::mysql->execute( "insert into openc3_monitor_tott ( uuid,type,caseuuid ) value('$uuid','$ctype','$x')" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $file };
};

true;
