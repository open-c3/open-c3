package api::systemstatus;
use Dancer ':syntax';
use Dancer qw(cookie);
use JSON qw();
use POSIX;
use api;
use uuid;
use Format;

=pod

管理/系统状态/获取所有状态列表详情

=cut

get '/systemstatus' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my @col = qw( id system module group name status timeout edit_time );
    my $res = eval{ $api::mysql->query( sprintf( "select %s from `openc3_connector_systemstatus`", join( ',',map{"`$_`"} @col ) ), \@col ) };

    my $config = eval{ YAML::XS::LoadFile "/data/Software/mydan/Connector/lib/api/systemstatus.yaml" };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $total = @$res;
    my $success = 0;

    for my $r ( @$res )
    {
        my $key = join '_', map{ $r->{$_} }qw( system module group name );
        ( $r->{key}, $r->{vkey} ) = ( $key, $key );

        $r->{info} = $config && $config->{$key} ? $config->{$key}[1] : '';

        ( $r->{info}, $r->{vkey} ) = ( 'CMDB.sync', "zz$r->{key}" ) if !$r->{info} && $r->{system} eq 'cmdb' && $r->{module} eq 'sync';

        $r->{status} = "$r->{status}.and.timeout" if $r->{timeout} && $r->{timeout} < time;
        $success ++ if $r->{status} eq 'success';
    }

    $res = [ sort{ $a->{vkey} cmp $b->{vkey} }@$res ];
    map{ delete $_->{vkey} }@$res;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $res, total => $total, success => $success };
};

=pod

管理/系统状态/获取某个服务日志内容

=cut

any '/systemstatus/log' => sub {
    my $param = params();
    my $error = Format->new( 
        system => qr/^[a-zA-Z\d_\-\.]+$/, 1,
        module => qr/^[a-zA-Z\d_\-\.]+$/, 1,
        group  => qr/^[a-zA-Z\d_\-\.]+$/, 1,
        name   => qr/^[a-zA-Z\d_\-\.]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $key = join '_', map{ $param->{$_} }qw( system module group name );

    my $res = +{ log => "log $key undef", detail => "" };

    my $config = eval{ YAML::XS::LoadFile "/data/Software/mydan/Connector/lib/api/systemstatus.yaml" };
    $res->{log} = "open-c3 system load config error: $@" if $@;

    if( $config && $config->{$key} )
    {
        $res->{log} = `tail -n 200 '$config->{$key}[0]'`;
        $res->{detail} = $config->{$key}[2];
    }
    elsif( $param->{system} eq 'cmdb' && $param->{module} eq 'sync' )
    {
        $res->{log} = `tail -n 300 '/tmp/cmdb.sync.$param->{group}.$param->{name}.log'`;
        $res->{detail} = "cmdb sync $param->{group}.$param->{name}";
    }

    $res->{log} = Encode::decode('utf8', $res->{log} );

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $res };
};

true;
