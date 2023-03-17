package api::device::jumpserverexipsite;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;

=pod

CMDB/跳板机/外网站点列表

=cut

my $dir = '/data/open-c3-data/device/curr/jumpserver/exipsite';

get '/device/jumpserverexipsite' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;
    my @x = `cd $dir && ls`;
    chomp @x;
    my $conf = [];
    map{ push @$conf, +{ name => $_ }; }@x;

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $conf };
};

=pod

CMDB/跳板机/添加外网站点

=cut

post '/device/jumpserverexipsite/:name' => sub {
    my $param = params();
    my $error = Format->new( 
        name => qr/^[a-zA-Z0-9][a-zA-Z0-9\-\_]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => "ADD JumpserverExipSite", content => "name:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $dpath = "$dir/$param->{name}";

    eval{ die "touch fail" if system "touch '$dpath'"; };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

=pod

CMDB/跳板机/删除外网站点

=cut

del '/device/jumpserverexipsite/:name' => sub {
    my $param = params();
    my $error = Format->new( 
        name => qr/^[a-zA-Z0-9][a-zA-Z0-9\-\_]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_root' ); return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    eval{ $api::auditlog->run( user => $user, title => "DEL JumpserverExipSite", content => "name:$param->{name}" ); };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $dpath = "$dir/$param->{name}";

    eval{ die "unlink fail" if system "rm '$dpath'"; };

    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};


true;
