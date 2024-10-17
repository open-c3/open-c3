package api::monitor::alert;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;
use LWP::UserAgent;

use POSIX;
use Time::Local;
use File::Temp;

sub gettime
{
    my $t = shift;
    return $t unless $t =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)\.\d+Z$/;
    my $x = timelocal($6,$5,$4,$3,$2-1,$1);
    return POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime( $x + 8 * 3600) );
}

=pod

监控系统/获取告警列表

=cut

get '/monitor/alert/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $projectid = $param->{projectid};

    my $ua = LWP::UserAgent->new;
    $ua->timeout( 3 );

    my $url = "http://OPENC3_ALERTMANAGER_IP:9093/api/v2/alerts";
    my $res = $ua->get( $url );
    unless( $res->is_success )
    {
        return +{ stat => $JSON::false, info => "get alert from altermanager error: $url" };
    }
    my $data = eval{JSON::decode_json $res->content};
    unless( !$@ && defined $data && ref $data eq 'ARRAY' )
    {
        return +{ stat => $JSON::false, info => "get alert from altermanager error: $url" };
    }

    map{ $_->{generatorURL} =~ s#http://[a-z0-9]+:9090/#$param->{siteaddr}/third-party/monitor/prometheus/# }@$data if $param->{siteaddr};

    map{
        $_->{annotations}{summary} =~ s#(\d+\.\d)\d+%#$1%#;
        $_->{annotations}{description} =~ s#(\d+\.\d)\d+%#$1%#;
        $_->{annotations}{value} =~ s#(\d+\.\d)\d+%#$1%#;
        $_->{startsAt} = gettime( $_->{startsAt} );
    }@$data;

    my @res = $projectid ? grep{ $_->{labels} && $_->{labels}{"fromtreeid"} && $_->{labels}{"fromtreeid"} eq $projectid }@$data : @$data;
    map{
        my $t = $_->{startsAt}; $t =~ s/ /T/g;
        $_->{uuid} = $_->{fingerprint} . '.'. $t;
    }@res;

    return +{ stat => $JSON::true, data => +{ map{ $_->{uuid} => 1 } @res } } if $param->{uuidonly};


    my $ips = join ' ', grep{ $_ &&  $_ =~ /^[a-zA-Z0-9][a-zA-Z0-9\.\-_:]+$/ }map{ $_->{labels}{instance} }@res;

    if( $ips )
    {
        for ( qw( v2-owner v3-alias v2-opsowner v2-tree v3-os ))
        {
            my ( $v, $type ) = split /\-/, $_;
            my @x = `c3mc-device-find-$v-$type $ips`;
            chomp @x;
            my %x;
            for ( @x )
            {
                my ( $k, $v ) = split / /, $_, 2;
                $k =~ s/:$//g;
                $x{$k} = Encode::decode( 'utf8', $v );
            }
            map{ $_->{$type} = $x{$_->{labels}{instance}} // '' if $_->{labels}{instance} }@res;
        }
    }

    @res = sort{ $b->{startsAt} cmp $a->{startsAt} }@res;
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \@res };
};

=pod

监控系统/告警转工单

=cut

post '/monitor/alert/tott/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;
    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my @cont = ( '从监控系统转过来的工单' );
    push @cont, "监控名称: " . Encode::encode("utf8", $param->{labels}{alertname}        );
    push @cont, "监控对象:"  . Encode::encode("utf8", $param->{labels}{instance}         );
    push @cont, "";
    push @cont, "概要: "     . Encode::encode("utf8", $param->{annotations}{summary}     );
    push @cont, "详情:"      . Encode::encode("utf8", $param->{annotations}{description} );
    push @cont, "";
    push @cont, "URL: "      . Encode::encode("utf8", $param->{generatorURL}             );

    my    $type = `c3mc-sys-ctl sys.monitor.tt.type`;
    chomp $type;
    my $ext_tt = $type ? '--ext_tt 1' : '';
    my $file;
    eval{
        my    $tmp = File::Temp->new( SUFFIX => ".tott", UNLINK => 0 );
        print $tmp join "\n", @cont;
        close $tmp;
        $file = $tmp->filename;
        my $title = "监控事件:" . Encode::encode("utf8",$param->{labels}{alertname} ). '['.Encode::encode("utf8",$param->{labels}{instance} ). ']';
        $title =~ s/'//g;
        my $x = `cat '$file'|c3mc-create-ticket --title '$title' $ext_tt --apply_user '$user' 2>&1`;
        die sprintf( "err: %s", Encode::decode("utf8", $x ) )if $?;
        $x =~ s/\n//g;
        die "create tt fail" unless $x && $x =~ /^[A-Z][A-Z0-9]+$/;
        my $uuid = $param->{uuid};
        die "uuid err: $uuid" unless $uuid && $uuid =~ /^[a-zA-Z0-9\.\-:]+$/;
        my $ctype = $type ? '1' : '0';
        $api::mysql->execute( "insert into openc3_monitor_tott ( uuid,type,caseuuid ) value('$uuid','$ctype','$x')" );
    };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $param->{uuid} };
};

=pod

监控系统/获取告警和工单的绑定关系

=cut

get '/monitor/alert/tottbind/:projectid' => sub {
    my $param = params();

    my $pmscheck = api::pmscheck( 'openc3_agent_read' ); return $pmscheck if $pmscheck;

    my @col = qw( uuid caseuuid);
    my $r = eval{ $api::mysql->query( sprintf( "select %s from openc3_monitor_tott", join( ',', @col)), \@col )}; 
    my %res;
    for my $x ( @$r )
    {
        $res{ $x->{uuid} } ||= [];
        push @{ $res{ $x->{uuid} } }, $x->{caseuuid};
    }
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => \%res };
};

=pod

监控系统/获取监控的工单url地址

=cut

get '/monitor/alert/gotocase/:projectid' => sub {
    my $param = params();
    my $error = Format->new(
        uuid     => qr/^[a-zA-Z0-9\.\-:]+$/, 1,
        caseuuid => qr/^[a-zA-Z0-9\.\-:]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read' ); return $pmscheck if $pmscheck;

    my $url = "/tt/#/tt/show/$param->{caseuuid}";
    my $r = eval{ $api::mysql->query( "select type from openc3_monitor_tott where uuid='$param->{uuid}' and caseuuid='$param->{caseuuid}'" )}; 
    return +{ stat => $JSON::false, info => $@ } if $@;
    if( @$r && $r->[0][0] )
    {
        my    $caseurl = `c3mc-sys-ctl sys.monitor.tt.caseurl`;
        chomp $caseurl;
        return +{ stat => $JSON::false, info => "sys.monitor.tt.caseurl undef" } unless $caseurl;
        $url = sprintf $caseurl, $param->{caseuuid};
    }
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $url };
};

true;
