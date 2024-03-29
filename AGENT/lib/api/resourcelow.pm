package api::resourcelow;
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
use OPENC3::DancerRun3;
use Encode;

=pod

监控系统/通用资源低负载/获取类型

=cut

get '/resourcelow/type' => sub {
    my $x = eval{ YAML::XS::LoadFile '/data/Software/mydan/Connector/pp/mmon/resourcelow/conf/type.yml' };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $x };
};

=pod

监控系统/通用资源低负载/获取状态

=cut

get '/resourcelow/status' => sub {
    my $x = eval{ YAML::XS::LoadFile '/data/Software/mydan/Connector/pp/mmon/resourcelow/conf/status.yml' };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $x };
};

=pod

监控系统/通用资源低负载/获取表格信息

=cut

get '/resourcelow/data/:type/:projectid' => sub {
    my $param = params();
    my $error = Format->new(
        type      => qr/^[a-z][a-z\d\-]*[a-z\d]$/, 1,
        projectid => qr/^\d+$/, 1,
        owner     => [ 'mismatch', qr/'/ ], 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my ( $chkfile ) = grep{ -f } ( "/data/open-c3-data/resourcelow/$param->{type}.yml", "/data/Software/mydan/Connector/pp/mmon/resourcelow/conf/chk/$param->{type}.yml" );

    my $chk = eval{ YAML::XS::LoadFile $chkfile };
    return +{ stat => $JSON::false, info => "load chk $chkfile fail: $@" } if $@;
    my $PolicyDescription = $chk->{PolicyDescription} && ref $chk->{PolicyDescription} eq 'HASH' ? $chk->{PolicyDescription} : +{};

    my ( $exit, $stderr, @x ) = OPENC3::DancerRun3::run3( "/data/Software/mydan/Connector/pp/mmon/resourcelow/gettable '$param->{type}' '$param->{projectid}'" );
    return +{ stat => $JSON::false, info => "get data fail:$stderr" } if $exit;
    my $title = shift @x;
    utf8::decode($title);
    my @title = split /;/, $title;

    my @node;
    for my $x ( @x )
    {
        utf8::decode($x);
        my @d = split /;/, $x;
        my %d = map{ $title[$_] => $d[$_] } 0 .. $#title;
        push @node, \%d;
    }

    if( $param->{owner} )
    {
        my $o = Encode::decode( 'utf8', '业务负责人' );
        @node = grep{ $_->{$o} && $_->{$o} eq $param->{owner} }@node;
    }

    return +{ stat => $JSON::true, data => \@node, title => \@title, PolicyDescription => $PolicyDescription };
};

=pod

监控系统/通用资源低负载/对资源进行标记

=cut

post '/resourcelow/mark/:type/:projectid' => sub {
    my $param = params();
    my $error = Format->new( 
        projectid => qr/^\d+$/, 1,
        uuids   => [ 'mismatch', qr/'/ ], 1,
        type    => [ 'mismatch', qr/'/ ], 1,
        status  => [ 'mismatch', qr/'/ ], 1,
        mark    => [ 'mismatch', qr/'/ ], 0,

    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{
        my @uuid = split /,/, $param->{uuids};
        while(@uuid)
        {
            my $x = join ',', splice @uuid, 0, 2;
            $api::auditlog->run( user => $user, title => 'ADD ResourceLowMark', content => "TREEID:$param->{projectid} UUIDS:$x" );
        }
    };
    return +{ stat => $JSON::false, info => $@ } if $@;

    $param->{mark} ||= '';

    my $status = eval{ YAML::XS::LoadFile '/data/Software/mydan/Connector/pp/mmon/resourcelow/conf/status.yml' };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $expires = time + 31 * 86400;
    for my $x ( @$status )
    {
        $expires = time + 86400 * $x->{expires} if $x->{name} eq $param->{status} && $x->{expires} && $x->{expires} =~ /^\d+$/;
    }

    eval{
        map{
            $api::mysql->execute( "replace into openc3_monitor_resource_low_mark(`type`,`uuid`,`operator`,`expires`,`status`,`mark`) values( '$param->{type}', '$_', '$user', '$expires', '$param->{status}', '$param->{mark}' )");
        }split /,/, $param->{uuids};
     };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

监控系统/通用资源低负载/获取标记MAP

=cut

get '/resourcelow/mark/:type/:projectid' => sub {
    my $param = params();
    my $error = Format->new(
        type  => [ 'mismatch', qr/'/ ], 1,
        projectid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', $param->{projectid} ); return $pmscheck if $pmscheck;

    my $r = eval{ $api::mysql->query( sprintf( "select uuid,status,mark from openc3_monitor_resource_low_mark  where expires>'%d'", time) )}; 
    return +{ stat => $JSON::false, info => $@ } if $@;
    my %mark = map{ $_->[0] => +{ status => $_->[1], mark => $_->[2] } }@$r;

    return +{ stat => $JSON::true, data => \%mark };
};

true;
