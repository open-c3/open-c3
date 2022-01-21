package api::monitor::sender;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use JSON;
use POSIX;
use api;
use Format;
use LWP::UserAgent;

any '/monitor/sender' => sub {
    return 'no params' unless my $params = params();
    my $uuid = sprintf "%s.%06d", POSIX::strftime( "%Y%m%d-%H%M%S", localtime ), rand 1000000;
    my $temp = "/data/open-c3-data/monitor-sender/sender.$uuid.wait";
    eval{ YAML::XS::DumpFile $temp, $params };
    return $@ || 'ok';
};

true;
