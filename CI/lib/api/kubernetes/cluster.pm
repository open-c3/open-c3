package api::kubernetes::cluster;
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

our %handle;

post '/kubernetes/cluster/connectiontest' => sub {
    my $param = params();
    my $error = Format->new( 
        kubectlVersion => qr/^v\d+\.\d+\.\d+$/, 1,
        kubeconfig => qr/.+/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my $fh = File::Temp->new( UNLINK => 0, SUFFIX => '.config', TEMPLATE => "/data/Software/mydan/tmp/kubeconfig_connectiontest_XXXXXXXX" );
    print $fh $param->{kubeconfig};
    close $fh;

    my $kubeconfig = $fh->filename;

    my ( $cmd, $handle ) = ( "KUBECONFIG=$kubeconfig kubectl version --short=true 2>&1", 'connectiontest' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    my $x = `$cmd`;
    my $status = ( $? >> 8 );
    return &{$handle{$handle}}( $x, $status ); 

};

$handle{connectiontest} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $status ? $JSON::false : $JSON::true, info => $x, };
};

true;
