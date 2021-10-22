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
    my $temp = sprintf "/data/Software/mydan/AGENT/sender/sender.%s.%s.wait", time, int rand 10000000;
    eval{ YAML::XS::DumpFile $temp, $params };
    return $@ || 'ok';
};

true;
