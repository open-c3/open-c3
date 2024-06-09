package api::exalarm::huawei;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;
use Digest::MD5;

=pod

扩展监控/接收华为监控数据

=cut

our %handle;
$handle{temp} = sub { return +{ info => shift, stat => shift ? $JSON::false : $JSON::true }; };

any '/exalarm/huawei' => sub {
    my $param = params();
    my $path = "/data/open-c3-data/monitor-exalarm";
    system( "mkdir -p '$path'" ) unless -d $path;
    my $uuid = sprintf "%s.%s", time, rand 10000;
    eval{ YAML::XS::DumpFile "$path/$uuid", $param };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true };
};

true;
