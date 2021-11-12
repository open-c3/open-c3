package api::kubernetes::shell;
use Dancer ':syntax';
use FindBin qw( $RealBin );
use Util;

any '/kubernetes/pod/shell' => sub {
    my $param = params();
    my ( $namespace, $name, $clusterid, $type, $siteaddr ) = @$param{qw( namespace name clusterid type siteaddr )};

    return "params undef" unless $namespace && $name && $clusterid && $type;
    return "no cookie" unless my $u = cookie( $api::cookiekey );

    redirect "$siteaddr/webshell/index.html?u=$u&clusterid=$clusterid&namespace=$namespace&name=$name&type=$type";
};

true;
