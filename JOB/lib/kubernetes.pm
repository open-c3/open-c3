package kubernetes;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use POSIX;
use Format;
use Time::Local;
use File::Temp;
use Digest::MD5;

sub getKubectlCmd($$$$$)
{
    my ( $db, $ticketid, $user, $company, $checkauth ) = @_;
    my $r = eval{ $db->query( "select ticket,create_user,share  from openc3_ci_ticket where id='$ticketid'" ); };
    die "ticket nofind by id $ticketid" unless $r && @$r;
    my ( $version, $ticket, $proxy ) = split /_:separator:_/, $r->[0][0], 3;

    die "no auth\n" if $checkauth && ! ( $r->[0][1] eq $user || $r->[0][2] eq $company ); 

    die "version format error in ticket" unless $version =~ /^v\d+\.\d+\.\d+$/;
    my $kubectl = $version eq 'v0.0.0' ? "kubectl" : "kubectl_$version";
    my $proxyenv = $proxy && $proxy =~ /^[a-zA-Z0-9:\.@]+$/ ? "HTTPS_PROXY='socks5://$proxy'" : "";

    my $md5 = Digest::MD5->new->add( $ticket )->hexdigest;
    my $kubeconfig = "/data/Software/mydan/tmp/kubeconfig_${ticketid}_$md5";
    return "KUBECONFIG=$kubeconfig $proxyenv $kubectl" if -f $kubeconfig;

    my $fh = File::Temp->new( UNLINK => 0, SUFFIX => '.config', TEMPLATE => "/data/Software/mydan/tmp/kubeconfig_${ticketid}_XXXXXXXX" );
    print $fh $ticket;
    close $fh;

    die "rename fail: $!" if system "mv '$fh' '$kubeconfig'";
    return "KUBECONFIG=$kubeconfig $proxyenv $kubectl";
}

true;
