package api::device;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON   qw();
use POSIX;
use api;

my $datapath = '/data/open-c3-data/device/curr';

get '/device/menu' => sub {
    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;

    my %re = map{ $_ => [] }qw( compute database domain networking others storage );

    for my $f ( sort glob "$datapath/*/*/data.tsv" )
    {
        my ( undef, $subtype, $type ) = reverse split /\//, $f;
        my    $c = `wc -l $f | awk '{print \$1}'`;
        chomp $c;
        push @{$re{$type}}, [ $subtype, $c - 1 ] if defined $re{$type};
    }

    return +{ stat => $JSON::true, data => \%re };
};


get '/device/data/:type/:subtype' => sub {
    my $param = params();
    my $error = Format->new(
        type       => qr/^[a-z\d\-_]+$/, 1,
        subtype    => qr/^[a-z\d\-_]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my $pmscheck = api::pmscheck( 'openc3_agent_read', 0 ); return $pmscheck if $pmscheck;
    my    @data = `cat $datapath/$param->{type}/$param->{subtype}/data.tsv`;
    chomp @data;

    my $title = shift @data;
    return +{ stat => $JSON::true, data => [] } unless @data;

    my @re;

    my $outline = eval{ YAML::XS::LoadFile "$datapath/$param->{type}/$param->{subtype}/outline.yml"; };
    return +{ stat => $JSON::false, info => "load outline fail: $@" } if $@;

    utf8::decode($title);
    my @title = split /\t/, $title;

    my @debug;
    for my $data ( @data )
    {
        utf8::decode($data);

        my @d = split /\t/, $data;

        my %d = map{ $title[ $_ ] => $d[ $_ ] } 0 .. @title - 1;
        push @debug , \%d if $param->{debug};
        push @re, +{
            map{
                $_ => join( ' | ', map{ $d{ $_ } || '' }@{ $outline->{ $_ } } )
            }qw( uuid baseinfo system contact )
        };
    }
    return +{ stat => $JSON::true, data => \@re, debug => \@debug };
};

true;
