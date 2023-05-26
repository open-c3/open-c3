package api::kubernetes::shell;
use Dancer ':syntax';
use FindBin qw( $RealBin );
use Util;

=pod

K8S/虚拟终端/进入POD

=cut

any '/kubernetes/pod/shell' => sub {
    my $param = params();
    my ( $namespace, $name, $clusterid, $type, $siteaddr, $grep ) = @$param{qw( namespace name clusterid type siteaddr grep )};

    my $grepstr = length $grep > 0 ? "&grep=$grep" : '';
    return "params undef" unless $namespace && $name && $clusterid && $type;
    return "no cookie" unless my $u = cookie( $api::cookiekey );

    redirect "$siteaddr/webshell/index.html?u=$u&clusterid=$clusterid&namespace=$namespace&name=$name&type=$type$grepstr";
};

=pod

K8S/虚拟终端/进入kubectl命令行

=cut

any '/kubernetes/kubectl/shell' => sub {
    my $param = params();
    my ( $clusterid, $siteaddr, $type ) = @$param{qw( clusterid siteaddr type )};

    return "params undef" unless $clusterid ;
    return "no cookie" unless my $u = cookie( $api::cookiekey );

    $type = 1 unless $type && $type eq 'full';
    redirect "$siteaddr/webshell/index.html?u=$u&clusterid=$clusterid&kubectl=$type";
};

true;
