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

    if( $config->{juyunappkey} )
    {
        $config->{juyunappname} ||= 'openc3';

        my $name = delete $config->{juyunappname};
        my $key = delete $config->{juyunappkey};

        return  +{ stat => $JSON::false, info => "juyun appname format error" } unless $name =~ /^[a-zA-Z0-9\-]+$/;
        return  +{ stat => $JSON::false, info => "juyun appkey format error" } unless $key =~ /^[a-zA-Z0-9\-]+$/;

        $config = YAML::XS::Dump YAML::XS::LoadFile "$RealBin/../config.ini/juyun";
        $config =~ s/appkey: xxxxxx/appkey: $key/g;
        $config =~ s/appname: openc3/appname: $name/g;
        $config = YAML::XS::Load $config;
    }

    my $BASE_PATH = "$RealBin/../../c3-front/dist";
    if( $config->{frontendstyle} && $config->{frontendstyle} eq 'juyun' )
    {
        system "sed -i 's#openc3_style_ctrl=\\\\\"[a-zA-Z0-9]*\\\\\"#openc3_style_ctrl=\\\\\"juyun\\\\\"#g' $BASE_PATH/scripts/*";
        system "sed -i 's/#f63/#24293e/g' $BASE_PATH/styles/*";
        system "sed -i 's/#e52/#293fbb/g' $BASE_PATH/styles/*";
    }
    else
    {
        system "sed -i 's#openc3_style_ctrl=\\\\\"[a-zA-Z0-9]*\\\\\"#openc3_style_ctrl=\\\\\"openc3\\\\\"#g' $BASE_PATH/scripts/*";
        system "sed -i 's/#24293e/#f63/g' $BASE_PATH/styles/*";
        system "sed -i 's/#293fbb/#e52/g' $BASE_PATH/styles/*";
    }

    if( $config->{gitreport2company} )
    {
        system "mkdir -p /data/glusterfs/gitreport/ && touch /data/glusterfs/gitreport/4000000000.watch";
    }
    else
    {
        system "rm /data/glusterfs/gitreport/4000000000.watch";
    }

    if( $config->{flowreport2company} )
    {
        system "mkdir -p /data/glusterfs/flowreport/ && touch /data/glusterfs/flowreport/4000000000.watch";
    }
    else
    {
        system "rm /data/glusterfs/flowreport/4000000000.watch";
    }


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
