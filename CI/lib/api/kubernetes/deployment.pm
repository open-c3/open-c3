package api::kubernetes::deployment;
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

K8S/获取deployment列表

=cut

get '/kubernetes/deployment' => sub {
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

    if( $param->{namespace} )
    {
        $filter->{rowfilter} = +{} if ( ! @ns ) || ( @ns && grep{ $_ eq $param->{namespace} }@ns );
    }

    my $argv = $param->{namespace} ? "-n $param->{namespace}" : "-A";
    my ( $cmd, $handle ) = ( "$kubectl get deployment $argv 2>/dev/null", 'showtable' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter );
};

true;
