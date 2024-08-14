package api::c3mc::cloud::control::redis_manage;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use JSON qw();
use POSIX;
use api;
use Format;
use Time::Local;
use File::Temp;
use api::c3mc;

our %handle = ();

=pod

云资源/控制/Redis/降级规格

=cut

get '/c3mc/cloud/control/redis_manage/downgrade/:type/:subtype/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        type    => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/,  1,
        subtype => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/,  1,
        uuid    => qr/^[a-zA-Z\d\-_\.:]+$/,          1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $filter = +{};

    my $cmd = "c3mc-cloud-control --type '$param->{type}' --subtype '$param->{subtype}' --uuid '$param->{uuid}' --ctrl capacity-downgrade x 2>&1";
    my $handle = 'cloud_redis_downgrade';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

=pod

云资源/控制/Redis/升级规格

=cut

get '/c3mc/cloud/control/redis_manage/upgrade/:type/:subtype/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        type    => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/,  1,
        subtype => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/,  1,
        uuid    => qr/^[a-zA-Z\d\-_\.:]+$/,          1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $filter = +{};

    my $cmd = "c3mc-cloud-control --type '$param->{type}' --subtype '$param->{subtype}' --uuid '$param->{uuid}' --ctrl capacity-upgrade x 2>&1";
    my $handle = 'cloud_redis_upgrade';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{cloud_redis_downgrade} = sub {
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;

    my $data = eval { JSON::decode_json($x) };
    return +{ stat => $JSON::false, info => "decode JSON fail: $@" } if $@;

    return +{ stat => $JSON::true, data => "From $data->{current_memory} To $data->{target_memory}" };
};

$handle{cloud_redis_upgrade} = sub {
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;

    my $data = eval { JSON::decode_json($x) };
    return +{ stat => $JSON::false, info => "decode JSON fail: $@" } if $@;

    return +{ stat => $JSON::true, data => "From $data->{current_memory} To $data->{target_memory}" };
};

true;
