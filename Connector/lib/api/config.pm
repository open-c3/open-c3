package api::config;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON;
use POSIX;
use MIME::Base64;
use api;
use Format;
use Util;
use uuid;
use FindBin qw( $RealBin );
use File::Basename;
use POSIX;

get '/config' => sub {
    my $param = params();
    my $error = Format->new(
        name => qr/^[a-zA-Z0-9]+$/, 1,
    )->check( %$param );
    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;


    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $config = eval{ YAML::XS::LoadFile "$RealBin/../config.ini/$param->{name}" };
    return +{ stat => $JSON::false, info => "load config fail:$@" } if $@;

    return +{ stat => $JSON::true, data => $config };

};

post '/config' => sub {
    my $param = params();
    my $config = params()->{config};
    return +{ stat => $JSON::false, info => 'nofind config in params' } unless $config;

    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my $time = POSIX::strftime( "%Y%m%d%H%M%S", localtime );

    eval{ $api::mysql->execute( "insert into openc3_connector_auditlog (`user`,`title`,`content`) values('$ssouser','EDIT CONNECTOR CONFIG','_')" ); };
    return  +{ stat => $JSON::false, info => $@ } if $@; 

    eval{
        YAML::XS::DumpFile "$RealBin/../config.ini/current", $config;
        die "copy config fail: $!" if system "cp $RealBin/../config.ini/current $RealBin/../config.ini/$time";
    };
    return +{ stat => $JSON::false, info => "dump config fail:$@" } if $@;

    return +{ stat => $JSON::true, info => 'ok' };
};

get '/config/list' => sub {
    my ( $ssocheck, $ssouser ) = api::ssocheck(); return $ssocheck if $ssocheck;
    my $pmscheck = api::pmscheck( 'openc3_connector_root' ); return $pmscheck if $pmscheck;

    my @list = map{ basename $_ } reverse glob "$RealBin/../config.ini/*";

    return +{ stat => $JSON::true, data => \@list };

};

true;
