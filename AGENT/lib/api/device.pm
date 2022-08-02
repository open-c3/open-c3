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

    my ( %re2, %subtypecount, %max );

    for my $type (  keys %re )
    {
        $re2{$type} = +{};
        for my $subtype ( @{ $re{$type} } )
        {
            my ( $name, $count ) = @{ $subtype };
            my ( $g, @alias ) = split /-/, $name;
            $subtypecount{$type}{$g} ++;
            $re2{$type}{$g} ||= [];
            push @{ $re2{$type}{$g}}, [ $g, @$subtype, join "-", @alias ];
            $max{$type} = @{ $re2{$type}{$g}} - 1 if $max{$type} < @{ $re2{$type}{$g}} - 1;
        }
    }

    for my $type (  keys %re )
    {
        for my $group ( keys %{ $re2{ $type  } } )
        {
            for ( 1.. 15 )
            {
                next unless @{ $re2{ $type  }{ $group }} <= $max{$type};
                push @{ $re2{ $type  }{ $group }}, [];
            }
        }
    }

    my %re3;
    for my $type ( keys %re2 )
    {
        $re3{ $type } = [];
        for my $group ( sort{ $subtypecount{$type}{$b} <=> $subtypecount{$type}{$a} }keys %{ $re2{ $type } } )
        {
            my @x = @{ $re2{ $type }{ $group } };
            map{ push @{ $re3{ $type }[ $_] }, $x[$_]  } 0 .. @x -1;
        }
    }

    return +{ stat => $JSON::true, data => \%re3 };
};


any '/device/data/:type/:subtype' => sub {
    my $param = params();
    my $error = Format->new(
        type       => qr/^[a-z\d\-_]+$/, 1,
        subtype    => qr/^[a-z\d\-_]+$/, 1,
#       grepdata
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

    my $filter = [];
    my $filterdata = {};
    my %filterdata;

    $filter = eval{ YAML::XS::LoadFile "$datapath/$param->{type}/$param->{subtype}/filter.yml"; } if -f "$datapath/$param->{type}/$param->{subtype}/filter.yml";
    return +{ stat => $JSON::false, info => "load filter fail: $@" } if $@;
    my %filter; map{ $filter{$_->{name}} = 1; $filterdata->{$_->{name}} = [];  }@$filter;

    utf8::decode($title);
    my @title = split /\t/, $title;

    my @debug;

    my $grepdata = $param->{grepdata} && ref $param->{grepdata} eq 'HASH' && %{ $param->{grepdata} } ?  $param->{grepdata} : undef;
    my $search = $grepdata && $grepdata->{_search_} ? delete $grepdata->{_search_} : undef;

    for my $data ( @data )
    {
        utf8::decode($data);

        my $searchmath = 1;
        if( $search )
        {
            $searchmath = 0 if index( $data, $search ) < 0;
        }
        my @d = split /\t/, $data;

        my %d = map{ $title[ $_ ] => $d[ $_ ] } 0 .. @title - 1;

        for my $f ( keys %filter )
        {
            $filterdata{$f}{$d{$f}} ++;
        }

        push @debug , \%d if $param->{debug};

        my $match = 1;
        if( $grepdata )
        {
            for my $grep ( keys %$grepdata )
            {
                $match = 0 if $grepdata->{$grep} ne $d{$grep};
            }
        }
        push @re, +{
            map{
                $_ => join( ' | ', map{ $d{ $_ } || '' }@{ $outline->{ $_ } } )
            }qw( uuid baseinfo system contact )
        } if $match && $searchmath;
    }

    for my $name ( keys %filterdata )
    {
        my %v = %{ $filterdata{$name} };
        for my $k ( sort{ $v{$b} <=> $v{$a} } keys %v )
        {
            push @{$filterdata->{$name}}, +{ name => $k, count => $v{$k} };
        }
    }
    return +{ stat => $JSON::true, data => \@re, debug => \@debug, filter => $filter, filterdata => $filterdata  };
};

true;
