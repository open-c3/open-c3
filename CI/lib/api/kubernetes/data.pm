package api::kubernetes::data;
use Dancer ':syntax';
use FindBin qw( $RealBin );
use Util;
use JSON;

get '/kubernetes/data/template/:name' => sub {
    my $param = params();
    my $error = Format->new( 
        name => qr/^[a-zA-Z0-9_]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $jsonstring = `yaml2json "/data/Software/mydan/CI/lib/api/kubernetes/data/$param->{name}.yaml"`;
    my $data = eval{decode_json $jsonstring};
    return $@ ? +{ stat => JSON::false, info => $@ } : +{ stat => JSON::true, data => $data };
};

any '/kubernetes/data/json2yaml' => sub {
    my $param = params();
    my $error = Format->new( 
        data => qr/.*/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    return  +{ stat => JSON::false, info => "data is null" } unless $param->{data};

    my $json = eval{encode_json $param->{data}};
    return +{ stat => JSON::false, info => $@ } if $@;
    my $fh = File::Temp->new( UNLINK => 0, SUFFIX => '.config', TEMPLATE => "/data/Software/mydan/tmp/temp_XXXXXXXX" );
    print $fh $json;
    close $fh;

    my $file = $fh->filename;
    my $data = `json2yaml $file`;

    return $@ ? +{ stat => JSON::false, info => $@ } : +{ stat => JSON::true, data => $data};
};

any '/kubernetes/data/json2yaml/perl' => sub {
    my $param = params();
    my $error = Format->new( 
        data => qr/.*/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $data = eval{ YAML::XS::Dump $param->{data}; };
    $data =~ s/: '(\d+)'\n/: "$1"\n/g;
    $data =~ s/: ''\n/: ""\n/g;
    $data =~ s/status: (False|True)\n/status: "$1"\n/g;
    $data =~ s/: ~\n/: null\n/g;
    $data =~ s/: (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)\n/: "$1"\n/g;
    $data =~ s/: (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+0\d:00)\n/: "$1"\n/g;

    $data =~ s#!!perl/scalar:JSON::PP::Boolean 0\n#false\n#g;
    $data =~ s#!!perl/scalar:JSON::PP::Boolean 1\n#true\n#g;

    $data =~ s#^---\n##;
    return $@ ? +{ stat => JSON::false, info => $@ } : +{ stat => JSON::true, data => $data};
};

any '/kubernetes/data/yaml2json' => sub {
    my $param = params();
    my $error = Format->new( 
        data => qr/.*/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    return  +{ stat => JSON::false, info => "data is null" } unless $param->{data};

    my $fh = File::Temp->new( UNLINK => 0, SUFFIX => '.config', TEMPLATE => "/data/Software/mydan/tmp/temp_XXXXXXXX" );
    print $fh $param->{data};
    close $fh;


    my $file = $fh->filename;
    my $jsonstring = `yaml2json $file`;
    my $data = eval{decode_json $jsonstring};

    return $@ ? +{ stat => JSON::false, info => $@ } : +{ stat => JSON::true, data => $data};
};

any '/kubernetes/data/yaml2json/perl' => sub {
    my $param = params();
    my $error = Format->new( 
        data => qr/.*/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    return  +{ stat => JSON::false, info => "data is null" } unless $param->{data};
    my $data = eval{ YAML::XS::Load $param->{data}; };
    return $@ ? +{ stat => JSON::false, info => $@ } : +{ stat => JSON::true, data => $data};
};

true;
