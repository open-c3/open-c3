package api::monitor::sender;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON qw();
use POSIX;
use api;
use Format;
use LWP::UserAgent;

=pod

监控系统/接收告警消息

系统内部接口，altermanager会调用该接口发送消息。

=cut

any '/monitor/sender' => sub {
    return 'no params' unless my $params = params();
    my $uuid = sprintf "%s.%06d", POSIX::strftime( "%Y%m%d-%H%M%S", localtime ), rand 1000000;
    my $temp = "/data/open-c3-data/monitor-sender/sender.$uuid.wait";
    eval{ YAML::XS::DumpFile $temp, +{ %$params, time => POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime ) } };
    return $@ || 'ok';
};

true;
