package api::kubernetes::app;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use JSON;
use POSIX;
use api;
use Format;
use Time::Local;
use File::Temp;
use api::kubernetes;

our %handle;

get '/kubernetes/app' => sub {
    my $param = params();
    my $error = Format->new( 
        namespace => qr/^[\w@\.\-]*$/, 0,
        status => qr/^[a-z]*$/, 0,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid} ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my $filter = +{ namespace => $param->{namespace}, status => $param->{status} };

    my ( $cmd, $handle ) = ( "$kubectl get all --all-namespaces -o wide", 'getall' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    my $x = `$cmd`;
    my $status = ( $? >> 8 );
    return &{$handle{$handle}}( $x, $status, $filter );
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

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid} ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl describe '$param->{type}' '$param->{name}' -n '$param->{namespace}'", 'getdescribe' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    my $x = `$cmd`;
    my $status = ( $? >> 8 );
    return &{$handle{$handle}}( $x, $status ); 
};

$handle{getdescribe} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $status ? $JSON::false : $JSON::true, data => $x, };
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

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid} ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::true, data => +{ kubecmd => "$kubectl rollout history '$param->{type}' '$param->{name}' -n '$param->{namespace}' -o yaml", handle => 'getyaml' }}
         if request->headers->{"openc3event"};


    my ( $cmd, $handle ) = ( "$kubectl rollout history '$param->{type}' '$param->{name}' -n '$param->{namespace}' -o yaml", 'getyaml' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    my $x = `$cmd`;
    my $status = ( $? >> 8 );
    return &{$handle{$handle}}( $x, $status ); 
};

$handle{getyaml} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $status ? $JSON::false : $JSON::true, data => $x, };
};

post '/kubernetes/app/apply' => sub {
    my $param = params();
    my $error = Format->new( 
        yaml => qr/.*/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    #TODO 用户ticket权限验证
    
    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid} ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    #check yaml 格式
    #dump成文件后继续检查格式，危险

    my $fh = File::Temp->new( UNLINK => 0, SUFFIX => '.yaml' );
    print $fh $param->{yaml};
    close $fh;

    my $filename = $fh->filename;

    my ( $cmd, $handle ) = ( "$kubectl apply -f '$filename' 2>&1", 'appapply' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    my $x = `$cmd`;
    my $status = ( $? >> 8 );
    return &{$handle{$handle}}( $x, $status ); 
};

$handle{appapply} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $status ? $JSON::false : $JSON::true, info => $x, };
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

    #TODO 用户ticket权限验证
    
    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid} ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl set image '$param->{type}/$param->{name}' '$param->{container}=$param->{image}' -n '$param->{namespace}' 2>&1", 'setimage' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    my $x = `$cmd`;
    my $status = ( $? >> 8 );
    return &{$handle{$handle}}( $x, $status ); 
};

$handle{setimage} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $status ? $JSON::false : $JSON::true, info => $x, };
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

    #TODO 用户ticket权限验证
    
    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid} ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl rollout undo $param->{type}/$param->{name} -n '$param->{namespace}' --to-revision=$param->{version}", 'setrollback' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    my $x = `$cmd`;
    my $status = ( $? >> 8 );
    return &{$handle{$handle}}( $x, $status ); 

};

$handle{setrollback} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $status ? $JSON::false : $JSON::true, info => $x, };
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

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid} ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "/data/Software/mydan/CI/bin/kubectl-history $kubectl rollout history $param->{type} $param->{name} -n '$param->{namespace}'", 'gethistory' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    my $x = `$cmd`;
    my $status = ( $? >> 8 );
    return &{$handle{$handle}}( $x, $status ); 

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

    #TODO 用户ticket权限验证

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid} ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl scale '$param->{type}' '$param->{name}' -n '$param->{namespace}' --replicas=$param->{replicas} 2>&1", 'setreplicas' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    my $x = `$cmd`;
    my $status = ( $? >> 8 );
    return &{$handle{$handle}}( $x, $status ); 

};

$handle{setreplicas} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $status ? $JSON::false : $JSON::true, info => $x, };
};

true;
