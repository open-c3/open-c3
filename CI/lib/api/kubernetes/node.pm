package api::kubernetes::node;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
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

K8S/节点管理/获取节点列表

=cut

get '/kubernetes/node' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl get node -o wide 2>/dev/null", 'getnode' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

$handle{getnode} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my @x = split /\n/, $x;

    my ( @title, @r ) = map{ s/-/_/g; split /\s+/, $_ } shift @x;
    splice @title,7, 0, splice @title, -2;

    map
    {
        my @col = split /\s+/, $_;
        splice @col,7, 0, splice @col, -2;
        splice @col, $#title, -1, join ' ',splice @col, $#title;
        push @r, +{ map{ $title[$_] => $col[$_]  }0..$#title };
        $r[-1]{stat} = +{  map{ $_ => 1 } split /,/, $r[-1]{STATUS} };
    }@x;

    return +{ stat => $JSON::true, data => \@r, };
};

=pod

K8S/节点管理/调度设置

对应K8S中的cordon操作

cordon:    不可调度
uncordon:  可调度

因为可以进行批量操作，在批量操作时候node传入数组格式。

=cut

post '/kubernetes/node/cordon' => sub {
    my $param = params();
    my $error = Format->new( 
        #node => qr/^[a-zA-Z0-9][a-zA-Z0-9_\.\-@]+$/, 1,    批量操作时请传入数组
        cordon => [ 'in', 'cordon', 'uncordon' ], 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    return  +{ stat => $JSON::false, info => "node undef" } unless $param->{node};

    my @node = ( ref $param->{node} eq 'ARRAY' ) ? @{ $param->{node} } : ( $param->{node} );

    map{ return +{ stat => $JSON::false, info => "node format error: $_" } unless $_ =~ /^[a-zA-Z0-9][a-zA-Z0-9_\.\-@]+$/ }@node;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;
    
    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'KUBERNETES CORDON', content => "ticketid:$param->{ticketid} cordon:$param->{cordon} node:$param->{node}" ); };

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl '$param->{cordon}' '$param->{node}' 2>&1", 'showinfo' );

    if( ref $param->{node} eq 'ARRAY' )
    {
         my $nodes = join " ", @node;
         $cmd = "echo $nodes|xargs -n 1|xargs -i{} bash -c \"$kubectl '$param->{cordon}' '{}' 2>&1 || exit 255\"";
    }

    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

=pod

K8S/节点管理/驱逐

对应K8S中的drain操作

因为可以进行批量操作，在批量操作时候node传入数组格式。

=cut

post '/kubernetes/node/drain' => sub {
    my $param = params();
    my $error = Format->new( 
        #node => qr/^[a-zA-Z0-9][a-zA-Z0-9_\.\-]+$/, 1, 批量操作时候传入数组
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;

    return  +{ stat => $JSON::false, info => "node undef" } unless $param->{node};

    my @node = ( ref $param->{node} eq 'ARRAY' ) ? @{ $param->{node} } : ( $param->{node} );
    map{ return +{ stat => $JSON::false, info => "node format error: $_" } unless $_ =~ /^[a-zA-Z0-9][a-zA-Z0-9_\.\-@]+$/ }@node;

    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;
    
    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'KUBERNETES DRAIN', content => "ticketid:$param->{ticketid} node:$param->{node}" ); };

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl drain '$param->{node}' --ignore-daemonsets 2>&1", 'showinfo' );
    if( ref $param->{node} eq 'ARRAY' )
    {
         my $nodes = join " ", @node;
         $cmd = "echo $nodes|xargs -n 1|xargs -i{} bash -c \"$kubectl drain '{}' --ignore-daemonsets 2>&1 || exit 255\"";
    }

    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

=pod

K8S/节点管理/污点信息获取

=cut

get '/kubernetes/node/taint' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        nodename => qr/^[a-zA-Z0-9\-\._\-]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "c3mc-k8s-node-taint -i $param->{ticketid} -n $param->{nodename} 2>/dev/null", 'getnodetaint' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

$handle{getnodetaint} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my ( @x, @r )= split /\n/, $x;
    for my $x ( @x )
    {
        my @s = split /\s+/, $x;
        push @r, +{ key => $s[0], value => $s[1], effect => $s[2] };

    }

    return +{ stat => $JSON::true, data => \@r, };
};

=pod

K8S/节点管理/污点设置

=cut

post '/kubernetes/node/taint' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        nodename => qr/^[a-zA-Z0-9\-\._\-]+$/, 1,
        key => qr/^[a-zA-Z0-9\-\._\/]+$/, 1,
        value => qr/^[a-zA-Z0-9\-\._]+$/, 1,
        effect => qr/^[a-zA-Z0-9\-\._]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'KUBERNETES TAINT SET', content => "ticketid:$param->{ticketid} nodename:$param->{nodename}" ); };

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl taint nodes $param->{nodename} '$param->{key}=$param->{value}:$param->{effect}' 2>/dev/null", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

=pod

K8S/节点管理/污点删除

=cut

del '/kubernetes/node/taint' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        nodename => qr/^[a-zA-Z0-9\-\._\-]+$/, 1,
        key => qr/^[a-zA-Z0-9\-\._\/]+$/, 1,
        effect => qr/^[a-zA-Z0-9\-\._]+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));
    eval{ $api::auditlog->run( user => $user, title => 'KUBERNETES TAINT DEL', content => "ticketid:$param->{ticketid} nodename:$param->{nodename}" ); };

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl taint nodes $param->{nodename} '$param->{key}:$param->{effect}-' 2>/dev/null", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

true;
