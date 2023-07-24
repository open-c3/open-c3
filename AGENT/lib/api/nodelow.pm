package api::nodelow;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use JSON qw();
use POSIX;
use MIME::Base64;
use api;
use Code;
use Format;

my $nodelow;
BEGIN { ( $nodelow ) = map{ Code->new( $_ ) }qw( nodelow ); };

=pod

监控系统/资源低负载/获取概要

=cut

get '/nodelow/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @node = eval{ $nodelow->run( db => $api::mysql, id => $param->{projectid} ) };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $ips = join ' ', grep{ $_ &&  $_ =~ /^\d+\.\d+\.\d+\.\d+$/ }map{ $_->{ip} }@node;

    if( $ips )
    {
        for my $type ( qw( owner instancetype hostname ))
        {
            my @x = `c3mc-device-find-$type $ips`;
            chomp @x;
            my %x;
            for ( @x )
            {
                my ( $k, $v ) = split /:/, $_, 2;
                $v =~ s/\s//g;
                $x{$k} = $v;
            }
            map{ $_->{$type} = $x{$_->{ip}} // '' if $_->{ip} }@node;
        }
    }

    my ( $chkfile ) = grep{ -f } ( "/data/open-c3-data/resourcelow/compute.yml", "/data/Software/mydan/Connector/pp/mmon/resourcelow/conf/chk/compute.yml" );

    my $chk = eval{ YAML::XS::LoadFile $chkfile };
    return +{ stat => $JSON::false, info => "load chk $chkfile fail: $@" } if $@;
    my $PolicyDescription = $chk->{PolicyDescription} && ref $chk->{PolicyDescription} eq 'HASH' ? $chk->{PolicyDescription} : +{};


    return +{ stat => $JSON::true, data => \@node, PolicyDescription => $PolicyDescription };
};

=pod

监控系统/资源低负载/获取单个资源详情

=cut

get '/nodelow/detail/:projectid/:ip' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        ip => qr/^[\d\.]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my @col = qw( date status mem cpu netin netout );
    my $r = eval{
        $api::mysql->query(
            sprintf( "select %s from openc3_monitor_node_low_detail
                where ip='$param->{ip}' order by date", join( ',', @col)), \@col )};

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $r };
};

=pod

监控系统/资源低负载/标记单个资源

=cut

any '/nodelow/mark/:projectid/:ip' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        ip        => qr/^[\d\.]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my    $owner = `c3mc-device-find-owner $param->{ip} |awk '{print \$2}'|head -n 1`;
    chomp $owner;

    return +{ stat => $JSON::false, info => "not authorized ,the ip $param->{ip} owner is $owner, and your current login account $user " } if $user ne $owner;
    eval{ $api::auditlog->run( user => $user, title => 'ADD NodeLowMark', content => "TREEID:$param->{projectid} IP:$param->{ip}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $expires = time + 31 * 86400;
    eval{ $api::mysql->execute( "replace into openc3_monitor_node_low_mark(`ip`,`operator`,`expires`) values( '$param->{ip}', '$user', '$expires' )") };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

监控系统/资源低负载/获取标记MAP

=cut

get '/nodelow/mark/:projectid' => sub {
    my $param = params();
    my $error = Format->new( projectid => qr/^\d+$/, 1 )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $r = eval{ $api::mysql->query( sprintf( "select ip from openc3_monitor_node_low_mark where expires>'%d'", time) )}; 
    return +{ stat => $JSON::false, info => $@ } if $@;
    my %mark = map{ $_->[0] => 1 }@$r;

    return +{ stat => $JSON::true, data => \%mark };
};

true;
