package api::kubernetes::app;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use MIME::Base64;
use FindBin qw( $RealBin );
use JSON;
use POSIX;
use api;
use Format;
use Time::Local;
use File::Temp;
use api::kubernetes;

our %handle = %api::kubernetes::handle;

get '/kubernetes/app' => sub {
    my $param = params();
    my $error = Format->new( 
        namespace => qr/^[\w@\.\-]*$/, 0,
        status => qr/^[a-z]*$/, 0,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my $filter = +{ namespace => $param->{namespace}, status => $param->{status} };

    my ( $cmd, $handle ) = ( "$kubectl get all --all-namespaces -o wide", 'getall' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $?, $filter );
 };

$handle{getall} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my @x = split /\n/, $x;

    my ( $deploymentready, $podready, $podrunning, $daemonsetready, $replicasetready ) = ( 0, 0, 0, 0, 0 );
    my $failonly = ( $filter->{status} && $filter->{status} eq 'fail' ) ? 1 : 0;
    my ( @r, @title, %r, %namespace );

    for my $line ( @x )
    {
        $line =~ s/NODE SELECTOR/NODE_SELECTOR/;
        $line =~ s/NOMINATED NODE/NOMINATED_NODE/;
        $line =~ s/READINESS GATES/READINESS_GATES/;
        $line =~ s/PORT\(S\)/PORT_S_/;

        next unless my @col = split /\s+/, $line;

        if( $col[0] eq 'NAMESPACE' )
        {
            @title = map{ $_ =~ s/\-/_/g; $_ }@col;
        }
        else
        {
            my $r = +{ map{ $title[$_] => $col[$_] } 0 ..  @title -1 };
            my ( $type ) = split /\//, $r->{NAME};
            $type =~ s/\.apps$//;
            $type = 'hpa' if $type eq 'horizontalpodautoscaler.autoscaling';
            $r->{type} = $type;
            $r{$type} = [] unless $r{$type};
            $namespace{$r->{NAMESPACE}} ++;

            next unless ( ! $filter->{namespace} )|| ( $filter->{namespace} eq $r->{NAMESPACE});

            if( $type eq 'deployment' )
            {
                if( $r->{READY} =~ /^(\d+)\/(\d+)$/  )
                {
                    if( $1 eq $2 && $1 ne 0 )
                    {
                        next if $failonly;
                        $deploymentready ++;
                        $r->{IREADY} = 1;
                    }
                    else
                    {
                        $r->{IREADY} = 0;
                    }
                }
            }
            if( $type eq 'pod' )
            {
                if( $r->{READY} =~ /^(\d+)\/(\d+)$/  )
                {
                    if( $1 eq $2 && $1 ne 0 )
                    {
                        $r->{IREADY} = 1;
                    }
                    else
                    {
                        $r->{IREADY} = 0;
                    }
                }
                if( $r->{STATUS} eq 'Running' )
                {
                    next if $r->{IREADY} && $failonly;
                    $podrunning ++;
                }

                $podready ++ if $r->{IREADY};
            }

            if( $type eq 'daemonset' )
            {
                next if( $failonly && ( $r->{DESIRED} eq $r->{READY} ) );
                $daemonsetready ++ if $r->{DESIRED} eq $r->{READY};
            }

            if( $type eq 'replicaset' )
            {
                next if( $failonly && ( $r->{DESIRED} eq $r->{READY} ) );
                $replicasetready ++ if $r->{DESIRED} eq $r->{READY};
            }

            $r->{INAME} = ( split /\//, $r->{NAME}, 2 )[1];
            push @{$r{$type}}, $r;
        }
    }

    return +{
        stat => $JSON::true,
        data => \%r,
        namespace => [ sort keys %namespace ],
        deploymentready => $deploymentready,
        podready => $podready,
        podrunning => $podrunning,
        daemonsetready => $daemonsetready,
        replicasetready => $replicasetready,
    };
};

get '/kubernetes/app/describe' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl describe '$param->{type}' '$param->{name}' -n '$param->{namespace}'", 'showdata' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

get '/kubernetes/app/describedeployment' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "/data/Software/mydan/CI/bin/kubectl-describedeployment '$kubectl' '$param->{namespace}' '$param->{name}'", 'getdescribedeployment' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

$handle{getdescribedeployment} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;

    my $data = eval{ YAML::XS::Load $x };
    return +{ stat => $JSON::false, info => $@, xx => $x } if $@;

    return +{ stat => $JSON::true, data => $data };
};

get '/kubernetes/app/describeingress' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "/data/Software/mydan/CI/bin/kubectl-describeingress '$kubectl' '$param->{namespace}' '$param->{name}'", 'getdescribeingress' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

$handle{getdescribeingress} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;

    my $data = eval{ YAML::XS::Load $x };
    return +{ stat => $JSON::false, info => $@, xx => $x } if $@;

    return +{ stat => $JSON::true, data => $data };
};

get '/kubernetes/app/describeservice' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "/data/Software/mydan/CI/bin/kubectl-describeservice '$kubectl' '$param->{namespace}' '$param->{name}'", 'getdescribeservice' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

$handle{getdescribeservice} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;

    my $data = eval{ YAML::XS::Load $x };
    return +{ stat => $JSON::false, info => $@, xx => $x } if $@;

    return +{ stat => $JSON::true, data => $data };
};


get '/kubernetes/app/yaml' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my %available = map{ $_ => 1 }qw( ingress service deployment daemonset pod replicaset hpa endpoints job statefulset );
    my $auth = $available{$param->{type}} ? 0 : 1;

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, $auth ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl get '$param->{type}' '$param->{name}' -n '$param->{namespace}' -o yaml", 'showdata' );
    #my ( $cmd, $handle ) = ( "$kubectl rollout history '$param->{type}' '$param->{name}' -n '$param->{namespace}' -o yaml", 'showdata' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

get '/kubernetes/app/yaml/always' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl get '$param->{type}' '$param->{name}' -n '$param->{namespace}' -o yaml 2>&1", 'getappyamlalways' );
    #my ( $cmd, $handle ) = ( "$kubectl rollout history '$param->{type}' '$param->{name}' -n '$param->{namespace}' -o yaml", 'showdata' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

$handle{getappyamlalways} = sub
{
    my ( $x, $status, $filter ) = @_;
    return $status ? +{ data => "", info => $x, stat =>  $x =~ /not found/ ?  $JSON::true : $JSON::false } : +{ stat => $JSON::true, data => $x };
};

get '/kubernetes/app/json' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my %available = map{ $_ => 1 }qw( ingress service deployment daemonset pod replicaset hpa endpoints job statefulset );
    my $auth = $available{$param->{type}} ? 0 : 1;

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, $auth ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl get '$param->{type}' '$param->{name}' -n '$param->{namespace}' -o json", 'getappjson' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

$handle{getappjson} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my $data = eval{ decode_json $x };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $data };
};

get '/kubernetes/app/flowlineinfo' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my $filter = +{ ticketid => $param->{ticketid}, kind => $param->{type}, namespace => $param->{namespace}, name => $param->{name} };

    my ( $cmd, $handle ) = ( "$kubectl get '$param->{type}' '$param->{name}' -n '$param->{namespace}' -o yaml", 'getflowlineinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $?, $filter ); 
};

$handle{getflowlineinfo} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my $yaml = eval{ YAML::XS::Load $x };
    return +{ stat => $JSON::false, info => $@ } if $@;

    my @r;
    for my $c ( @{$yaml->{spec}{template}{spec}{containers}} )
    {
        push @r, +{ image => $c->{image}, repository => $c->{image},  container => $c->{name}, %$filter };
        $r[-1]{repository} =~ s#:[^:/]+$##;
#        $r[-1]{base64} = eval{ encode_base64( encode('UTF-8', YAML::XS::Dump $r[-1] )); };
    }
    return +{ stat => $JSON::true, data => \@r };
};

post '/kubernetes/app/apply' => sub {
    my $param = params();
    my $error = Format->new( 
        yaml => qr/.*/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    #check yaml 格式
    #dump成文件后继续检查格式，危险

    my $fh = File::Temp->new( UNLINK => 0, SUFFIX => '.yaml' );
    print $fh $param->{yaml};
    close $fh;

    my $filename = $fh->filename;

    my ( $cmd, $handle ) = ( "$kubectl apply -f '$filename' 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

post '/kubernetes/app/create' => sub {
    my $param = params();
    my $error = Format->new( 
        yaml => qr/.*/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    #check yaml 格式
    #dump成文件后继续检查格式，危险

    my $fh = File::Temp->new( UNLINK => 0, SUFFIX => '.yaml' );
    print $fh $param->{yaml};
    close $fh;

    my $filename = $fh->filename;

    my ( $cmd, $handle ) = ( "$kubectl create -f '$filename' 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

post '/kubernetes/app/setimage' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        container => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        image => qr/^[\w@\.\-\/:]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl set image '$param->{type}/$param->{name}' '$param->{container}=$param->{image}' -n '$param->{namespace}' 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

post '/kubernetes/app/rollback' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        version => qr/^\d+$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl rollout undo $param->{type}/$param->{name} -n '$param->{namespace}' --to-revision=$param->{version}", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

get '/kubernetes/app/rollback' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "/data/Software/mydan/CI/bin/kubectl-history $kubectl rollout history $param->{type} $param->{name} -n '$param->{namespace}'", 'gethistory' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

$handle{gethistory} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my @x = split /\n/, $x;
    my @r;
    for( @x )
    {
        my @t = split /\s+/, $_, 3;
        next unless $t[0] =~ /^\d+$/;
        push @r, +{ REVISION => $t[0], IMAGE => $t[1], CHANGE_CAUSE  => $t[2], }
    }
    return +{ stat => $JSON::true, data => \@r };
};

post '/kubernetes/app/setreplicas' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        replicas => qr/\d+$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl scale '$param->{type}' '$param->{name}' -n '$param->{namespace}' --replicas=$param->{replicas} 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

post '/kubernetes/app/delete' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl delete '$param->{type}' '$param->{name}' -n '$param->{namespace}' 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

true;
