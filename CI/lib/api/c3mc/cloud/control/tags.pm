package api::c3mc::cloud::control::tags;
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

our %handle = %api::kubernetes::handle;

=pod

云资源/控制/Tags/获取资源tag

=cut

get '/c3mc/cloud/control/tags/get/:type/:subtype/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        type    => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/,  1,
        subtype => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/,  1,
        uuid    => qr/^[a-zA-Z0-9][a-zA-Z0-9\-_]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my $filter = +{};

    my $conf = eval{ YAML::XS::LoadFile "/data/Software/mydan/AGENT/device/conf/template/sync-$param->{subtype}.yml" };
    return  +{ stat => $JSON::false, info => "load sync-$param->{subtype}.yml fail: $@" } if $@;

    return  +{ stat => $JSON::false, info => "sync-$param->{subtype}.yml content format error: $@" }
        unless $conf->{download} && ref $conf->{download} eq 'ARRAY' && @{$conf->{download}} && $conf->{download}[0]{url};

    my @url = split /\|/, $conf->{download}[0]{url};

    my $chtag = '';
    map{ $chtag = " | $_ " if $_ =~ /^\s*c3mc-cloud-tag-v2/ }@url;

    my $cmd = "c3mc-cloud-control --type '$param->{type}' --subtype '$param->{subtype}' --uuid '$param->{uuid}' --ctrl get x $chtag 2>&1";
    my $handle = 'cloud_tags_get';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{cloud_tags_get} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    my @res;
    my @cont = split /\n/, $x;
    my $data = eval{JSON::decode_json $x};

    my $tag = [];
    $tag = [ map{ +{ key => $_, value => $data->{tag}{$_} } } sort keys %{$data->{tag}} ] if $data->{tag} && ref $data->{tag} eq 'HASH';

    return +{ stat => $JSON::true, data => $tag };
};

=pod

云资源/控制/Tags/添加或者编辑资源tag

=cut

post '/c3mc/cloud/control/tags/add/:type/:subtype/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        type        => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/,  1,
        subtype     => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/,  1,
        uuid        => qr/^[a-zA-Z0-9][a-zA-Z0-9\-_]+$/, 1,
        tagkey      => qr/^[a-zA-Z0-9][a-zA-Z0-9\-_]+$/, 1,
        tagvalue    => qr/^[a-zA-Z0-9][a-zA-Z0-9\-_]+$/, 1,

    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $filter = +{};

    my $cmd = "c3mc-cloud-control --type '$param->{type}' --subtype '$param->{subtype}' --uuid '$param->{uuid}' --ctrl tag-add '$param->{tagkey}=$param->{tagvalue}' 2>&1";
    my $handle = 'cloud_tags_add';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{cloud_tags_add} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    return +{ stat => $JSON::true, data => 'ok' };
};

=pod

云资源/控制/Tags/删除资源tag

=cut

post '/c3mc/cloud/control/tags/del/:type/:subtype/:uuid' => sub {
    my $param = params();
    my $error = Format->new( 
        type        => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/,  1,
        subtype     => qr/^[a-zA-Z0-9][a-zA-Z0-9\-]+$/,  1,
        uuid        => qr/^[a-zA-Z0-9][a-zA-Z0-9\-_]+$/, 1,
        tagkey      => qr/^[a-zA-Z0-9][a-zA-Z0-9\-_]+$/, 1,
        tagvalue    => qr/^[a-zA-Z0-9][a-zA-Z0-9\-_]+$/, 1,

    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
 
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my $filter = +{};

    my $cmd = "c3mc-cloud-control --type '$param->{type}' --subtype '$param->{subtype}' --uuid '$param->{uuid}' --ctrl tag-delete '$param->{tagkey}=$param->{tagvalue}' 2>&1";
    my $handle = 'cloud_tags_del';
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{cloud_tags_del} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, info => $x } if $status;
    return +{ stat => $JSON::true, data => 'ok' };
};

true;
