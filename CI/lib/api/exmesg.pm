package api::exmesg;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;
use Digest::MD5;

=pod

扩展监控/接收扩展的告警数据

=cut

any '/exmesg/:type' => sub {
    my $param = params();
    my $path = "/data/open-c3-data/monitor-exmesg/queue";
    system( "mkdir -p '$path'" ) unless -d $path;
    my $uuid = sprintf "%s.%s", time, rand 10000;
    eval{ YAML::XS::DumpFile "$path/$uuid", $param };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
