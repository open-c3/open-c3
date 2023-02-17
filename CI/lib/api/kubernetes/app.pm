package api::kubernetes::app;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use MIME::Base64;
use FindBin qw( $RealBin );
use JSON qw();
use POSIX;
use api;
use Format;
use Time::Local;
use File::Temp;
use api::kubernetes;

our %handle = %api::kubernetes::handle;

=pod

K8S/获取应用列表

=cut

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

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my $filter = +{
        namespace => $param->{namespace},
        status    => $param->{status},
        rowfilter => +{ key => \@ns, col => [ 'NAMESPACE' ] } ,
    };

    #my ( $cmd, $handle ) = ( "$kubectl get all --all-namespaces -o wide 2>/dev/null", 'getall' );
    my ( $cmd, $handle ) = ( "c3mc-k8s-kubectl-getallresource $param->{ticketid} 2>/dev/null", 'getall' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter );
};

$handle{getall} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my @x = split /\n/, $x;

    my ( $deploymentready, $podready, $podrunning, $daemonsetready, $replicasetready ) = ( 0, 0, 0, 0, 0 );
    my $failonly = ( $filter->{status} && $filter->{status} eq 'fail' ) ? 1 : 0;
    my ( %r, @r, @title ) = map{ $_ => [] }qw( service deployment daemonset pod replicaset statefulset hpa job.batch cronjob.batch ingressroute ingressroutetcp );
    
    for my $line ( @x )
    {
        $line =~ s/NODE SELECTOR/NODE_SELECTOR/;
        $line =~ s/NOMINATED NODE/NOMINATED_NODE/;
        $line =~ s/READINESS GATES/READINESS_GATES/;
        $line =~ s/PORT\(S\)/PORT_S_/;
        $line =~ s/SCHEDULE/SCHEDULE1 SCHEDULE2 SCHEDULE3 SCHEDULE4 SCHEDULE5/;
        $line =~ s/LAST SCHEDULE/LAST_SCHEDULE/;

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

    for my $kind ( keys %r )
    {
        next unless ref $r{$kind} eq 'ARRAY' && @{$r{$kind}};
        $r{$kind} = [ api::kubernetes::rowfilter( $filter, @{$r{$kind}} ) ];
    }

    return +{
        stat => $JSON::true,
        data => \%r,
        deploymentready => $deploymentready,
        podready => $podready,
        podrunning => $podrunning,
        daemonsetready => $daemonsetready,
        replicasetready => $replicasetready,
    };
};

=pod

K8S/获取应用YAML内容

=cut

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

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, $auth ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $param->{namespace} }@ns;

    my ( $cmd, $handle ) = ( "$kubectl get '$param->{type}' '$param->{name}' -n '$param->{namespace}' -o yaml 2>/dev/null", 'showdata' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

=pod

K8S/获取应用YAML内容/总是

与上一个接口不一样的地方是，如果应用不存在，会返回空的内容。

在创建和编辑应用的时候，前端需要显示diff内容。

该接口在获取不存在的应用时，查询K8S发现该应用不存在时，接口会返回空。

=cut

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

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $param->{namespace} }@ns;

    my ( $cmd, $handle ) = ( "$kubectl get '$param->{type}' '$param->{name}' -n '$param->{namespace}' -o yaml 2>&1", 'getappyamlalways' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

$handle{getappyamlalways} = sub
{
    my ( $x, $status, $filter ) = @_;
    return $status ? +{ data => "", info => $x, stat =>  $x =~ /not found/ ?  $JSON::true : $JSON::false } : +{ stat => $JSON::true, data => $x };
};

=pod

K8S/获取应用json内容

=cut

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

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, $auth ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $param->{namespace} }@ns;

    my ( $cmd, $handle ) = ( "$kubectl get '$param->{type}' '$param->{name}' -n '$param->{namespace}' -o json 2>/dev/null", 'getappjson' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

$handle{getappjson} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my $data = eval{ JSON::from_json $x };
    return $@ ? +{ stat => $JSON::false, info => $@ } : +{ stat => $JSON::true, data => $data };
};

=pod

K8S/获取应用中的数据给流水线

返回应用的镜像地址，仓库等信息，在配置流水线的时候用于提取

=cut

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

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $param->{namespace} }@ns;

    my $filter = +{ ticketid => $param->{ticketid}, kind => $param->{type}, namespace => $param->{namespace}, name => $param->{name} };

    my ( $cmd, $handle ) = ( "$kubectl get '$param->{type}' '$param->{name}' -n '$param->{namespace}' -o yaml 2>/dev/null", 'getflowlineinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{getflowlineinfo} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my $yaml = eval{ YAML::XS::Load Encode::encode('utf8', $x ) };

    return +{ stat => $JSON::false, info => $@ } if $@;

    my @r;
    for my $c ( @{$yaml->{spec}{template}{spec}{containers}} )
    {
        push @r, +{ image => $c->{image}, repository => $c->{image},  container => $c->{name}, %$filter };
        $r[-1]{repository} =~ s#:[^:/]+$##;
        $r[-1]{repository} =~ s#@.*$##;
    }
    return +{ stat => $JSON::true, data => \@r };
};

=pod

K8S/提交变更配置到K8S中

对应K8S中的apply命令

=cut

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

    eval{ $api::auditlog->run( user => $user, title => 'KUBERNETES APPLY', content => "ticketid:$param->{ticketid}" ); };

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    #check yaml 格式
    #dump成文件后继续检查格式，危险
    if( @ns )
    {
        my $yamldata = eval{ YAML::XS::Load $param->{yaml} };
        return +{ stat => $JSON::false, info => "check yaml fail: $@" } if $@;
        return +{ stat => $JSON::false, info => "nofind metadata.namespace in yaml" } unless $yamldata->{metadata} && $yamldata->{metadata}{namespace};
        return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $yamldata->{metadata}{namespace} }@ns;
    }

    my $fh = File::Temp->new( UNLINK => 0, SUFFIX => '.yaml' );
    print $fh $param->{yaml};
    close $fh;

    my $filename = $fh->filename;

    my ( $cmd, $handle ) = ( "$kubectl apply -f '$filename' 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

=pod

K8S/提交新配置到K8S中

对应K8S中的create命令

=cut

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

    eval{ $api::auditlog->run( user => $user, title => 'KUBERNETES CREATE', content => "ticketid:$param->{ticketid}" ); };

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    #check yaml 格式
    #dump成文件后继续检查格式，危险
    if( @ns )
    {
        my $yamldata = eval{ YAML::XS::Load $param->{yaml} };
        return +{ stat => $JSON::false, info => "check yaml fail: $@" } if $@;
        return +{ stat => $JSON::false, info => "nofind metadata.namespace in yaml" } unless $yamldata->{metadata} && $yamldata->{metadata}{namespace};
        return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $yamldata->{metadata}{namespace} }@ns;
    }

    my $fh = File::Temp->new( UNLINK => 0, SUFFIX => '.yaml' );
    print $fh $param->{yaml};
    close $fh;

    my $filename = $fh->filename;

    my ( $cmd, $handle ) = ( "$kubectl create -f '$filename' 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

=pod

K8S/对应用进行回滚

=cut

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

    eval{ $api::auditlog->run( user => $user, title => 'KUBERNETES ROLLBACK', content => "ticketid:$param->{ticketid} namespace:$param->{namespace} type:$param->{type} name:$param->{name} version:$param->{version}" ); };

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $param->{namespace} }@ns;

    my ( $cmd, $handle ) = ( "$kubectl rollout undo $param->{type}/$param->{name} -n '$param->{namespace}' --to-revision=$param->{version} 2>/dev/null", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

=pod

K8S/获取应用可回滚的版本列表

=cut

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

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $param->{namespace} }@ns;

    my ( $cmd, $handle ) = ( "/data/Software/mydan/CI/bin/kubectl-history $kubectl rollout history $param->{type} $param->{name} -n '$param->{namespace}' 2>/dev/null", 'gethistory' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
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

=pod

K8S/删除应用

对应K8S中的delete命令

=cut

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

    eval{ $api::auditlog->run( user => $user, title => 'KUBERNETES DELETE', content => "ticketid:$param->{ticketid} namespace:$param->{namespace} type:$param->{type} name:$param->{name}" ); };

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $param->{namespace} }@ns;

    my ( $cmd, $handle ) = ( "$kubectl delete '$param->{type}' '$param->{name}' -n '$param->{namespace}' 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

true;
