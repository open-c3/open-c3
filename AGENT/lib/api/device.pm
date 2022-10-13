package api::device;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON   qw();
use POSIX;
use api;

my $datapath = '/data/open-c3-data/device/curr';

sub getdatacount
{
    my ( $datafile, $greptreename, $treeid, $type, $subtype  ) = @_;
    if( $greptreename )
    {
        my    @data = `c3mc-device-cat $type $subtype`;
        chomp @data;

        my $title = shift @data;

        utf8::decode($title);
        my @title = split /\t/, $title;

        my $colmap;
        my $cmf = $datafile;
        $cmf =~ s/data.tsv$/colmap.yml/;
        if( -f $cmf )
        {
            $colmap = eval{ YAML::XS::LoadFile $cmf; };
            die "load colmap fail: $@" if $@;
        }

        my $treenamecol = ( $colmap && $colmap->{treename} ) ? $colmap->{treename} : undef;

        my $c = 0;
        for my $data ( @data )
        {
             utf8::decode($data);
             my @d = split /\t/, $data;

             my %d = map{ $title[ $_ ] => $d[ $_ ] } 0 .. @title - 1;

            my $treenamematch = 1;
            if( $greptreename )
            {
                if( $treenamecol )
                {
                     $treenamematch = 0 unless $d{ $treenamecol }  && grep{ ( $_ eq $greptreename || ( 0 == index( $_ , "$greptreename."  ) ) )}split /,/, $d{ $treenamecol };
                }
                else
                {
                     $treenamematch = 0 unless $treeid == 4000000000;
                }
            }

             $c ++ if $treenamematch;

        }
        return $c;
    }
    else
    {
        my $c = `wc -l $datafile | awk '{print \$1}'`;
        chomp $c;
        return $c -1;
    }
};

get '/device/menu/:treeid' => sub {
    my $param = params();
    my $error = Format->new(
        treeid     => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my %re = map{ $_ => [] }qw( compute database domain networking others storage );
    return +{ stat => $JSON::true, data => \%re  } if ! $param->{treeid} || $param->{treeid} > 4000000000;

    my $pmscheck = $param->{treeid} == 4000000000
        ? api::pmscheck( 'openc3_job_root'                    )
        : api::pmscheck( 'openc3_job_write', $param->{treeid} );
    return $pmscheck if $pmscheck;

    my $greptreename = $param->{treeid} == 4000000000 ? undef : eval{ gettreename( $param->{treeid} ) };;
    return +{ stat => $JSON::false, info => $@ } if $@;

    for my $f ( sort glob "$datapath/*/*/data.tsv" )
    {
        my ( undef, $subtype, $type ) = reverse split /\//, $f;
        my $c = getdatacount( $f, $greptreename, $param->{treeid}, $type, $subtype );
        next unless $c > 0;
        push @{$re{$type}}, [ $subtype, $c ] if defined $re{$type};
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


sub gettreename
{
    my $treeid = shift @_;
    my @x = `c3mc-base-treemap cache| grep "^$treeid;"|awk -F';'  '{print \$2}'`;
    chomp @x;
    die "get treename by id: $treeid fail" unless @x;
    return $x[0];
};

any '/device/data/:type/:subtype/:treeid' => sub {
    my $param = params();
    my $error = Format->new(
        type       => qr/^[a-z\d\-_]+$/, 1,
        subtype    => qr/^[a-z\d\-_]+$/, 1,
        treeid     => qr/^\d+$/, 1,
#       grepdata
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    return +{ stat => $JSON::true, data => []  } if ! $param->{treeid} || $param->{treeid} > 4000000000;

    my $pmscheck = $param->{treeid} == 4000000000
        ? api::pmscheck( 'openc3_job_root'                    )
        : api::pmscheck( 'openc3_job_write', $param->{treeid} );
    return $pmscheck if $pmscheck;

    my $greptreename = $param->{treeid} == 4000000000 ? undef : eval{ gettreename( $param->{treeid} ) };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my ( $getdatacmd, $currdatapath ) = $param->{type} eq 'all' && $param->{subtype} eq 'all'
        ? ( 'c3mc-device-cat-all',                               $datapath                                  )
        : ( "c3mc-device-cat $param->{type} $param->{subtype}", "$datapath/$param->{type}/$param->{subtype}");

    my    @data = `$getdatacmd`;
    chomp @data;

    my $title = shift @data;
    return +{ stat => $JSON::true, data => [] } unless @data;

    my @re;

    my $outline = eval{ YAML::XS::LoadFile "$currdatapath/outline.yml"; };
    return +{ stat => $JSON::false, info => "load outline fail: $@" } if $@;

    my $colmap;
    if( -f "$currdatapath/colmap.yml" )
    {
        $colmap = eval{ YAML::XS::LoadFile "$currdatapath/colmap.yml"; };
        return +{ stat => $JSON::false, info => "load colmap fail: $@" } if $@;
    }

    my $treenamecol = ( $colmap && $colmap->{treename} ) ? $colmap->{treename} : undef;

    my $filter = [];
    my $filterdata = {};
    my %filterdata;

    $filter = eval{ YAML::XS::LoadFile "$currdatapath/filter.yml"; } if -f "$currdatapath/filter.yml";
    return +{ stat => $JSON::false, info => "load filter fail: $@" } if $@;
    my %filter; map{ $filter{$_->{name}} = 1; $filterdata->{$_->{name}} = [];  }@$filter;

    utf8::decode($title);
    my @title = split /\t/, $title;

    my @debug;

    my $grepdata = $param->{grepdata} && ref $param->{grepdata} eq 'HASH' && %{ $param->{grepdata} } ?  $param->{grepdata} : undef;
    if( $grepdata )
    {
        for my $grep ( keys %$grepdata )
        {
            delete $grepdata->{$grep} if $grepdata->{$grep} eq '';
            $grepdata->{$grep} = ""   if $grepdata->{$grep} eq '_null_';
        }
        $grepdata = undef unless %$grepdata;
    }
 
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

        my $treenamematch = 1;
        if( $greptreename )
        {
            if( $treenamecol )
            {
                 $treenamematch = 0 unless $d{ $treenamecol }  && grep{ ( $_ eq $greptreename || ( 0 == index( $_ , "$greptreename."  ) ) )}split /,/, $d{ $treenamecol };
            }
            else
            {
                 $treenamematch = 0 unless $param->{greeid} == 4000000000;
            }
        }

        my $match = 1;
        if( $grepdata )
        {
            for my $grep ( keys %$grepdata )
            {
                $match = 0 if $grepdata->{$grep} ne $d{$grep};
            }
        }

        my ( $ctype, $csubtype ) = $param->{type} eq 'all' && $param->{subtype} eq 'all' ? ( $d{type}, $d{subtype} ) : ( $param->{type}, $param->{subtype} );

        push @re, +{
            type    => $ctype,
            subtype => $csubtype,
            map{
                $_ => join( ' | ', map{ $d{ $_ } || '' }@{ $outline->{ $_ } } )
            }qw( uuid baseinfo system contact )
        } if $match && $searchmath && $treenamematch;
    }

    for my $name ( keys %filterdata )
    {
        my %v = %{ $filterdata{$name} };
        for my $k ( sort{ $v{$b} <=> $v{$a} } keys %v )
        {
            push @{$filterdata->{$name}}, +{ name => $k eq "" ? "_null_" : $k, count => $v{$k} };
        }
    }
    return +{ stat => $JSON::true, data => \@re, debug => \@debug, filter => $filter, filterdata => $filterdata  };
};

any '/device/detail/:type/:subtype/:treeid/:uuid' => sub {
    my $param = params();
    my $error = Format->new(
        type       => qr/^[a-z\d\-_]+$/, 1,
        subtype    => qr/^[a-z\d\-_]+$/, 1,
        treeid     => qr/^\d+$/, 1,
        uuid       => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    return +{ stat => $JSON::true, data => []  } if $param->{treeid} > 4000000000;
    my $pmscheck = $param->{treeid} == 4000000000
        ? api::pmscheck( 'openc3_job_root'                    )
        : api::pmscheck( 'openc3_job_write', $param->{treeid} );
    return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $greptreename = $param->{treeid} == 4000000000 ? undef : eval{ gettreename( $param->{treeid} ) };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my    @data = `c3mc-device-cat $param->{type} $param->{subtype}`;
    chomp @data;

    my $title = shift @data;
    return +{ stat => $JSON::true, data => [] } unless @data;

    my @re;

    my $colmap;
    if( -f "$datapath/$param->{type}/$param->{subtype}/colmap.yml" )
    {
        $colmap = eval{ YAML::XS::LoadFile "$datapath/$param->{type}/$param->{subtype}/colmap.yml"; };
        return +{ stat => $JSON::false, info => "load colmap fail: $@" } if $@;
    }

    my $uuidcol = ( $colmap && $colmap->{uuid} ) ? $colmap->{uuid} : 'UUID';
    my $treenamecol = ( $colmap && $colmap->{treename} ) ? $colmap->{treename} : undef;

    utf8::decode($title);
    my @title = split /\t/, $title;

    for my $data ( @data )
    {
        utf8::decode($data);
        my @d = split /\t/, $data;
        my %d = map{ $title[ $_ ] => $d[ $_ ] } 0 .. @title - 1;

        my $treenamematch = 1;
        if( $greptreename )
        {
            if( $treenamecol )
            {
                 $treenamematch = 0 unless $d{ $treenamecol }  && grep{ ( $_ eq $greptreename || ( 0 == index( $_ , "$greptreename."  ) ) )}split /,/, $d{ $treenamecol };
            }
            else
            {
                 $treenamematch = 0 unless $param->{greeid} == 4000000000;
            }
        }

        next unless $treenamematch;

        push @re , \%d if ( $d{ $uuidcol } && $d{ $uuidcol } eq $param->{uuid} );

    }


    my $showmysqlauth = 0;
    my @showmysqladdr;
    my $ingestionmysqlfile = "$datapath/$param->{type}/$param->{subtype}/ingestion-mysql.yml";
    if( -f $ingestionmysqlfile && -f "/data/open-c3-data/device/auth/mysql.auth/$user" )
    {
        my $ingestionmysql = eval{ YAML::XS::LoadFile $ingestionmysqlfile };
        return  +{ stat => $JSON::false, info => "load ingestion-mysql.yml fail: $@" } if $@;

        @showmysqladdr = @{$ingestionmysql->{addr}};
        $showmysqlauth = 1;
    }

    my $showredisauth = 0;
    my @showredisaddr;
    my $ingestionredisfile = "$datapath/$param->{type}/$param->{subtype}/ingestion-redis.yml";
    if( -f $ingestionredisfile && -f "/data/open-c3-data/device/auth/redis.auth/$user" )
    {
        my $ingestionredis = eval{ YAML::XS::LoadFile $ingestionredisfile };
        return  +{ stat => $JSON::false, info => "load ingestion-redis.yml fail: $@" } if $@;

        @showredisaddr = @{$ingestionredis->{addr}};
        $showredisauth = 1;
    }
 
    my $showmongodbauth = 0;
    my @showmongodbaddr;
    my $ingestionmongodbfile = "$datapath/$param->{type}/$param->{subtype}/ingestion-mongodb.yml";
    if( -f $ingestionmongodbfile && -f "/data/open-c3-data/device/auth/mongodb.auth/$user" )
    {
        my $ingestionmongodb = eval{ YAML::XS::LoadFile $ingestionmongodbfile };
        return  +{ stat => $JSON::false, info => "load ingestion-mongodb.yml fail: $@" } if $@;

        @showmongodbaddr = @{$ingestionmongodb->{addr}};
        $showmongodbauth = 1;
    }
 
    my @re2;
    for my $r ( @re )
    {
        map{
            $r->{$_} =~ s/_sys_temp_newline_temp_sys_/\n/g;
            $r->{$_} =~ s/_sys_temp_delimiter_temp_sys_/\t/g;
        } @title;
        my @x = map{ [ $_ => $r->{$_} ] } @title;

        if( $showmysqlauth )
        {
            my $mysqladdr = join ':',map{ $r->{$_}} @showmysqladdr;
            push @x, [ _mysqladdr_ => $mysqladdr ];

            my $mysqlpath = '/data/open-c3-data/device/auth/mysql';
            system "mkdir -p $mysqlpath" unless -d $mysqlpath;

            my $mysqlfile = "$mysqlpath/$mysqladdr";
            my $mysqlauth = '';
            if( -f $mysqlfile )
            {
                $mysqlauth = eval{ YAML::XS::LoadFile "$mysqlpath/$mysqladdr"; };
                return  +{ stat => $JSON::false, info => "get mysql auth fail: $@" } if $@;
            }
            push @x, [ _mysqlauth_ => $mysqlauth ];

        }

        if( $showredisauth )
        {
            my $redisaddr = join ':',map{ $r->{$_}} @showredisaddr;
            push @x, [ _redisaddr_ => $redisaddr ];

            my $redispath = '/data/open-c3-data/device/auth/redis';
            system "mkdir -p $redispath" unless -d $redispath;

            my $redisfile = "$redispath/$redisaddr";
            my $redisauth = '';
            if( -f $redisfile )
            {
                $redisauth = eval{ YAML::XS::LoadFile "$redispath/$redisaddr"; };
                return  +{ stat => $JSON::false, info => "get redis auth fail: $@" } if $@;
            }
            $redisauth =~ s/^_://;
            push @x, [ _redisauth_ => $redisauth ];
        }
 
        if( $showmongodbauth )
        {
            my $mongodbaddr = join ':',map{ $r->{$_}} @showmongodbaddr;
            push @x, [ _mongodbaddr_ => $mongodbaddr ];

            my $mongodbpath = '/data/open-c3-data/device/auth/mongodb';
            system "mkdir -p $mongodbpath" unless -d $mongodbpath;

            my $mongodbfile = "$mongodbpath/$mongodbaddr";
            my $mongodbauth = '';
            if( -f $mongodbfile )
            {
                $mongodbauth = eval{ YAML::XS::LoadFile "$mongodbpath/$mongodbaddr"; };
                return  +{ stat => $JSON::false, info => "get mongodb auth fail: $@" } if $@;
            }
            push @x, [ _mongodbauth_ => $mongodbauth ];
        }

        push @re2, \@x;
    }

    return +{ stat => $JSON::true, data => \@re2, treenamecol => $treenamecol };
};

true;
