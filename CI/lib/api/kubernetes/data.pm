package api::kubernetes::data;
use Dancer ':syntax';
use FindBin qw( $RealBin );
use Util;
use JSON;

get '/kubernetes/data/template/deployment' => sub {
    my $data =eval{ YAML::XS::LoadFile '/data/Software/mydan/CI/lib/api/kubernetes/data/deployment.yaml' };
    return $@ ? +{ stat => JSON::false, xx => $@ } : +{ stat => JSON::true, data => $data};
};
true;
