package api::device;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use JSON   qw();
use POSIX;
use api;
use OPENC3::Tree;

my $authstrict;
BEGIN{
    my $x = `c3mc-sys-ctl sys.device.auth.strict`;
    chomp $x;
    $authstrict = defined $x && $x eq '0' ? 0 : 1;
};

my $database = '/data/open-c3-data/device';

sub getdatacount
{
    my ( $timemachine, $datafile, $greptreename, $treeid, $type, $subtype  ) = @_;
    if( $greptreename )
    {
        my    @data = `c3mc-device-cat $timemachine $type $subtype`;
        chomp @data;

        my $title = shift @data;

        return 0 unless $title;
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
                     $treenamematch = 0 unless $treeid == 0;
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

=pod

CMDB/获取菜单

=cut

get '/device/menu/:treeid' => sub {
    my $param = params();
    my $error = Format->new(
        treeid       => qr/^\d+$/, 1,
        timemachine  => qr/^[a-z0-9][a-z0-9\-]+[a-z0-9]$/, 1,
    )->check( %$param );

    $param->{treeid} = 0 if $param->{treeid} eq 4000000000;

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    my %re = map{ $_ => [] }qw( compute database domain networking others storage );
    return +{ stat => $JSON::true, data => \%re  } if $param->{treeid} >= 4000000000;

    my $pmscheck;
    if( $authstrict )
    {
          $pmscheck = $param->{treeid} == 0
            ? api::pmscheck( 'openc3_job_root'                    )
            : api::pmscheck( 'openc3_job_write', $param->{treeid} );
    }
    else
    {
          $pmscheck = api::pmscheck( 'openc3_job_read', $param->{treeid} );
    }
    return $pmscheck if $pmscheck;

    my $greptreename = $param->{treeid} == 0 ? undef : eval{ gettreename( $param->{treeid} ) };;
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $datapathx = $param->{timemachine} eq 'curr' ? "$database/curr" : "$database/timemachine/$param->{timemachine}";
    for my $f ( sort glob "$datapathx/*/*/data.tsv" )
    {
        my ( undef, $subtype, $type ) = reverse split /\//, $f;
        my $c = getdatacount( $param->{timemachine}, $f, $greptreename, $param->{treeid}, $type, $subtype );
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
            $max{$type} ||= 0;
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

=pod

CMDB/获取子分类的表格

=cut

any '/device/data/:type/:subtype/:treeid' => sub {
    my $param = params();
    my $error = Format->new(
        type         => qr/^[a-z\d\-_]+$/, 1,
        subtype      => qr/^[a-z\d\-_]+$/, 1,
        treeid       => qr/^\d+$/, 1,
        timemachine  => qr/^[a-z0-9][a-z0-9\-]+[a-z0-9]$/, 1,
#       grepdata
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    $param->{treeid} = 0 if $param->{treeid} eq 4000000000;

    return +{ stat => $JSON::true, data => []  } if $param->{treeid} >= 4000000000;

    my $pmscheck;
    if( $authstrict )
    {
          $pmscheck = $param->{treeid} == 0
            ? api::pmscheck( 'openc3_job_root'                    )
            : api::pmscheck( 'openc3_job_write', $param->{treeid} );
    }
    else
    {
          $pmscheck = api::pmscheck( 'openc3_job_read', $param->{treeid} );
    }
    return $pmscheck if $pmscheck;

    my $greptreename = $param->{treeid} == 0 ? undef : eval{ gettreename( $param->{treeid} ) };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my $datapathx = $param->{timemachine} eq 'curr' ? "$database/curr" : "$database/timemachine/$param->{timemachine}";

    my ( $getdatacmd, $currdatapath ) = $param->{type} eq 'all' && $param->{subtype} eq 'all'
        ? ( "c3mc-device-cat-all --timemachine $param->{timemachine}",                 $datapathx)
        : ( "c3mc-device-cat $param->{timemachine} $param->{type} $param->{subtype}", "$datapathx/$param->{type}/$param->{subtype}");

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
    my %filtermatch;

    $filter = eval{ YAML::XS::LoadFile "$currdatapath/filter.yml"; } if -f "$currdatapath/filter.yml";
    return +{ stat => $JSON::false, info => "load filter fail: $@" } if $@;
    my %filter; map{ $filter{$_->{name}} = 1; $filterdata->{$_->{name}} = []; }@$filter;

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
                 $treenamematch = 0 unless $param->{greeid} == 0;
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

        next unless $match && $searchmath && $treenamematch;

        map{ $d{ $_ } = OPENC3::Tree::merge( $d{ $_ } ) if $d{ $_ }; }( '_tree_', $treenamecol );

        push @re, +{
            type    => $ctype,
            subtype => $csubtype,
            map{
                $_ => join( ' | ', map{ $d{ $_ } || '' }@{ $outline->{ $_ } } )
            }qw( uuid baseinfo system contact )
        };

        for my $f ( keys %filter )
        {
            $filtermatch{$f}{$d{$f}} ++;
        }
 
    }

    for my $name ( keys %filterdata )
    {
        my %v = %{ $filterdata{$name} };
        my %vm = $filtermatch{$name} && ref $filtermatch{$name} eq 'HASH' ? %{ $filtermatch{$name} } : ();
        map{ $vm{$_} ||= 0 }keys %v;
        for my $k ( sort{ $vm{$b} <=> $vm{$a} } keys %v )
        {
            push @{$filterdata->{$name}}, +{ name => $k eq "" ? "_null_" : $k, count => $vm{$k}||0 };
        }
    }
    return +{ stat => $JSON::true, data => \@re, debug => \@debug, filter => $filter, filterdata => $filterdata  };
};

=pod

CMDB/获取单个资源的详情

=cut

any '/device/detail/:type/:subtype/:treeid/:uuid' => sub {
    my $param = params();
    my $error = Format->new(
        type         => qr/^[a-z\d\-_]+$/, 1,
        subtype      => qr/^[a-z\d\-_]+$/, 1,
        treeid       => qr/^\d+$/, 1,
        uuid         => qr/^[a-zA-Z0-9][a-zA-Z\d\-_\.:]+$/, 1,
        timemachine  => qr/^[a-z0-9][a-z0-9\-]+[a-z0-9]$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    $param->{treeid} = 0 if $param->{treeid} eq 4000000000;

    return +{ stat => $JSON::true, data => []  } if $param->{treeid} >= 4000000000;

    my $pmscheck;
    if( $authstrict )
    {
          $pmscheck = $param->{treeid} == 0
            ? api::pmscheck( 'openc3_job_root'                    )
            : api::pmscheck( 'openc3_job_write', $param->{treeid} );
    }
    else
    {
          $pmscheck = api::pmscheck( 'openc3_job_read', $param->{treeid} );
    }
    return $pmscheck if $pmscheck;

    my $user = $api::sso->run( cookie => cookie( $api::cookiekey ), map{ $_ => request->headers->{$_} }qw( appkey appname ) );

    my $greptreename = $param->{treeid} == 0 ? undef : eval{ gettreename( $param->{treeid} ) };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my    @data = `c3mc-device-cat '$param->{timemachine}' $param->{type} $param->{subtype}`;
    chomp @data;

    my $title = shift @data;
    return +{ stat => $JSON::true, data => [] } unless @data;

    my @re;

    my $datapathx = $param->{timemachine} eq 'curr' ? "$database/curr" : "$database/timemachine/$param->{timemachine}";
    my $colmap;
    if( -f "$datapathx/$param->{type}/$param->{subtype}/colmap.yml" )
    {
        $colmap = eval{ YAML::XS::LoadFile "$datapathx/$param->{type}/$param->{subtype}/colmap.yml"; };
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
                 $treenamematch = 0 unless $param->{greeid} == 0;
            }
        }

        next unless $treenamematch;

        push @re , \%d if ( $d{ $uuidcol } && $d{ $uuidcol } eq $param->{uuid} );

    }


    my $showmysqlauth = 0;
    my @showmysqladdr;
    my $mysqladdrtail = '';
    my $ingestionmysqlfile = "$datapathx/$param->{type}/$param->{subtype}/ingestion-mysql.yml";
    if( -f $ingestionmysqlfile && -f "$datapathx/auth/mysql.auth/$user" )
    {
        my $ingestionmysql = eval{ YAML::XS::LoadFile $ingestionmysqlfile };
        return  +{ stat => $JSON::false, info => "load ingestion-mysql.yml fail: $@" } if $@;

        @showmysqladdr = ref $ingestionmysql->{addr} ? @{$ingestionmysql->{addr}} : ( $ingestionmysql->{addr} );
        $mysqladdrtail = ':3306' if ref $ingestionmysql->{addr} && @{$ingestionmysql->{addr}} <= 1;
        $showmysqlauth = 1;
    }

    my $showredisauth = 0;
    my @showredisaddr;
    my $redisaddrtail = '';
    my $ingestionredisfile = "$datapathx/$param->{type}/$param->{subtype}/ingestion-redis.yml";
    if( -f $ingestionredisfile && -f "$datapathx/auth/redis.auth/$user" )
    {
        my $ingestionredis = eval{ YAML::XS::LoadFile $ingestionredisfile };
        return  +{ stat => $JSON::false, info => "load ingestion-redis.yml fail: $@" } if $@;

        @showredisaddr = ref $ingestionredis->{addr} ? @{$ingestionredis->{addr}} : ( $ingestionredis->{addr} );
        $redisaddrtail = ":6379" if ref $ingestionredis->{addr} && @{$ingestionredis->{addr}} <= 1;
        $showredisauth = 1;
    }
 
    my $showmongodbauth = 0;
    my @showmongodbaddr;
    my $mongodbaddrtail = '';
    my $ingestionmongodbfile = "$datapathx/$param->{type}/$param->{subtype}/ingestion-mongodb.yml";
    if( -f $ingestionmongodbfile && -f "$datapathx/auth/mongodb.auth/$user" )
    {
        my $ingestionmongodb = eval{ YAML::XS::LoadFile $ingestionmongodbfile };
        return  +{ stat => $JSON::false, info => "load ingestion-mongodb.yml fail: $@" } if $@;

        @showmongodbaddr = ref $ingestionmongodb->{addr} ? @{$ingestionmongodb->{addr}} : ( $ingestionmongodb->{addr} );
        $mongodbaddrtail = ':27017' if ref $ingestionmongodb->{addr} && @{$ingestionmongodb->{addr}} <= 1;
        $showmongodbauth = 1;
    }
 
    my @re2;
    for my $r ( @re )
    {
        map{
            $r->{$_} =~ s/_sys_temp_newline_temp_sys_/\n/g;
            $r->{$_} =~ s/_sys_temp_delimiter_temp_sys_/\t/g;
        } @title;
        my @x = map{ [ $_ => $r->{$_} ] } grep{ ! ( $_ =~ /\./ && $r->{$_} eq "" ) }@title;

        if( -f "$datapathx/auth/$param->{type}-$param->{subtype}.auth/$user" )
        {
            my $passfile = "$datapathx/auth/$param->{type}-$param->{subtype}/$r->{$uuidcol}";
            my $passcont = '';
            if( -f $passfile )
            {
                $passcont = eval{ YAML::XS::LoadFile $passfile };
                return  +{ stat => $JSON::false, info => "get auth fail: $@" } if $@;
            }
            push @x, [ _auth_ => $passcont ];
        }

        if( $showmysqlauth )
        {
            my $mysqladdr = join ':',map{ $r->{$_}} @showmysqladdr;
            $mysqladdr .= $mysqladdrtail;
            push @x, [ _mysqladdr_ => $mysqladdr ];

            my $mysqlpath = "$datapathx/auth/mysql";
            system "mkdir -p $mysqlpath" unless -d $mysqlpath;

            my $mysqlfile = "$mysqlpath/$mysqladdr";
               $mysqlfile = "$mysqlpath/default" unless -f $mysqlfile;
            my $mysqlauth = '';
            if( -f $mysqlfile )
            {
                $mysqlauth = eval{ YAML::XS::LoadFile $mysqlfile; };
                return  +{ stat => $JSON::false, info => "get mysql auth fail: $@" } if $@;
            }
            push @x, [ _mysqlauth_ => $mysqlauth ];

        }

        if( $showredisauth )
        {
            my $redisaddr = join ':',map{ $r->{$_}} @showredisaddr;
            $redisaddr .= $redisaddrtail;
            push @x, [ _redisaddr_ => $redisaddr ];

            my $redispath = "$datapathx/auth/redis";
            system "mkdir -p $redispath" unless -d $redispath;

            my $redisfile = "$redispath/$redisaddr";
               $redisfile = "$redispath/default" unless -f $redisfile;
            my $redisauth = '';
            if( -f $redisfile )
            {
                $redisauth = eval{ YAML::XS::LoadFile $redisfile; };
                return  +{ stat => $JSON::false, info => "get redis auth fail: $@" } if $@;
            }
            $redisauth =~ s/^_://;
            push @x, [ _redisauth_ => $redisauth ];
        }
 
        if( $showmongodbauth )
        {
            my $mongodbaddr = join ':',map{ $r->{$_}} @showmongodbaddr;
            $mongodbaddr .= $mongodbaddrtail;
            push @x, [ _mongodbaddr_ => $mongodbaddr ];

            my $mongodbpath = "$datapathx/auth/mongodb";
            system "mkdir -p $mongodbpath" unless -d $mongodbpath;

            my $mongodbfile = "$mongodbpath/$mongodbaddr";
               $mongodbfile = "$mongodbpath/default" unless -f $mongodbfile;
            my $mongodbauth = '';
            if( -f $mongodbfile )
            {
                $mongodbauth = eval{ YAML::XS::LoadFile $mongodbfile; };
                return  +{ stat => $JSON::false, info => "get mongodb auth fail: $@" } if $@;
            }
            push @x, [ _mongodbauth_ => $mongodbauth ];
        }

        push @re2, \@x;
    }

    my $util = eval{ YAML::XS::LoadFile "$datapathx/$param->{type}/$param->{subtype}/util.yml"; };
    return  +{ stat => $JSON::false, info => "get util fail: $@" } if $@;
    my %extcol = ();
    if( $util && $util->{extcol} )
    {
        map{
            $_->{alias} //= $_->{name};
            $extcol{ $_->{name} } = $_;
        }@{ $util->{extcol} };
    }
    my $grpcol = $util->{grpcol} && ref $util->{grpcol} eq 'HASH' ? $util->{grpcol} : +{ baseinfo => [], system => [] };
    return +{ stat => $JSON::true, data => \@re2, treenamecol => $treenamecol, extcol => \%extcol, grpcol => $grpcol };
};

=pod

CMDB/获取时间机器列表

=cut

get '/device/timemachine' => sub {
    my @x = `cd /data/open-c3-data/device/timemachine && ls`;
    chomp @x;
    return +{ stat => $JSON::true, data => [ reverse sort grep{ /^\d+\-\d+$/ }@x] };
};

true;
