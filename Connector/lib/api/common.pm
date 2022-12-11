package api::common;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use POSIX;

get '/common/i18n' => sub {
    my $data = eval{ YAML::XS::LoadFile "/data/Software/mydan/Connector/lib/api/i18n.yaml"; };
    return +{ stat => $JSON::false, info => "load i18n.yaml fail: $@" } if $@;

    my %d;
    for my $k ( keys %$data )
    {
        my @d = ref $data->{$k} ? @{$data->{$k}} : ( $data->{$k} );
        $d{en}{C3T}{ $k } = $d[0];
        $d{zh}{C3T}{ $k } = @d > 1 ? $d[1] : $k;
    }
    
    my @data = (
        +{
            id      => 1,
            lang    => "简体中文",
            langkey => "zh_CN",
            data    => JSON::to_json $d{zh},
        },
        +{
            id      => 2,
            lang    => "English",
            langkey => "en",
            data    => JSON::to_json $d{en},
        },
    );

    return +{ stat => $JSON::true, data => \@data };
};

true;
