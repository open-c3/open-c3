package api::kubernetes::cluster;
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

our %handle = %api::kubernetes::handle;

=pod

K8S/集群/集群的链接测试/通过配置进行测试

测试一下集群是不是可用的, 测试的网络权限等

=cut

post '/kubernetes/cluster/connectiontest' => sub {
    my $param = params();
    my $error = Format->new( 
        kubectlVersion => qr/^v\d+\.\d+\.\d+$/, 1,
        proxyAddr => qr/^[a-zA-Z0-9:\.@]*$/, 0,
        kubeconfig => qr/.+/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_root' ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));
    eval{ $api::auditlog->run( user => $user, title => 'KUBERNETES CONNECTIONTEST', content => "kubectlVersion:$param->{kubectlVersion}" ); };

    my $fh = File::Temp->new( UNLINK => 0, SUFFIX => '.config', TEMPLATE => "/data/Software/mydan/tmp/kubeconfig_connectiontest_XXXXXXXX" );
    print $fh $param->{kubeconfig};
    close $fh;

    my $kubeconfig = $fh->filename;
    my $proxyenv = $param->{proxyAddr} ? "HTTPS_PROXY='socks5://$param->{proxyAddr}'" : "";

    my ( $cmd, $handle ) = ( "KUBECONFIG=$kubeconfig $proxyenv kubectl version --short=true 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

=pod

K8S/集群/集群的链接测试/指定测试已经存在的集群

测试一下集群是不是可用的, 测试的网络权限等

=cut

post '/kubernetes/cluster/connectiontest/:ticketid' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;
    
    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));
    eval{ $api::auditlog->run( user => $user, title => 'KUBERNETES CONNECTIONTEST', content => "ticketid:$param->{ticketid}" ); };

    my ( $kubectl, @ns )= eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my ( $cmd, $handle ) = ( "$kubectl version --short=true 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

true;
