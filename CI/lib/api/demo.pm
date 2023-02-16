package api::demo;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);

use YAML::XS;

=pod

DEMO/QA的回调接口

=cut

any '/demo/qa/callback' => sub {
    my $param = params();
    eval{ YAML::XS::DumpFile "/tmp/openc3.demo.qa.callback.temp", $param };
    return $@ ? "err: $@" : 'ok';
};

true;
