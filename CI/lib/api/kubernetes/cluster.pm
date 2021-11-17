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
$handle{showinfo} = sub { return +{ info => shift, stat => shift ? $JSON::false : $JSON::true }; };

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

    my ( $cmd, $handle ) = ( "KUBECONFIG=$kubeconfig kubectl version --short=true 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

true;
