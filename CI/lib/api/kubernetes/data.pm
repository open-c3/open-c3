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
    $data =~ s/'(\d+)'\n/$1\n/g;
    return $@ ? +{ stat => JSON::false, info => $@ } : +{ stat => JSON::true, data => $data};
};

true;
