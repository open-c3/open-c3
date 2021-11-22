package api::kubernetes::data;
use Dancer ':syntax';
use FindBin qw( $RealBin );
use Util;
use JSON;

get '/kubernetes/data/template/:name' => sub {
    my $param = params();
    my $error = Format->new( 
        name => qr/^[a-z]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;


    my $data =eval{ YAML::XS::LoadFile "/data/Software/mydan/CI/lib/api/kubernetes/data/$param->{name}.yaml" };
    return $@ ? +{ stat => JSON::false, info => $@ } : +{ stat => JSON::true, data => $data };
};

any '/kubernetes/data/json2yaml' => sub {
    my $param = params();
    my $error = Format->new( 
        data => qr/.*/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $data = eval{ YAML::XS::Dump $param->{data}; };
    $data =~ s/: '(\d+)'\n/: $1\n/g;
    $data =~ s/status: (False|True)\n/status: "$1"\n/g;
    $data =~ s/Timestamp: ~\n/Timestamp: null\n/g;
    $data =~ s/Time: ~\n/Time: null\n/g;
    $data =~ s/: (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)\n/: "$1"\n/g;
    $data =~ s/: (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+0\d:00)\n/: "$1"\n/g;
    $data =~ s/resourceVersion: (\d+)\n/resourceVersion: "$1"\n/g;
    $data =~ s#deployment.kubernetes.io/revision: (\d+)\n#deployment.kubernetes.io/revision: "$1"\n#g;

    $data =~ s#^---\n##;
    return $@ ? +{ stat => JSON::false, info => $@ } : +{ stat => JSON::true, data => $data};
};

any '/kubernetes/data/yaml2json' => sub {
    my $param = params();
    my $error = Format->new( 
        data => qr/.*/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $data = eval{ YAML::XS::Load $param->{data}; };
    return $@ ? +{ stat => JSON::false, info => $@ } : +{ stat => JSON::true, data => $data};
};

true;
