package api::kubernetes::service;
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

get '/kubernetes/service' => sub {
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

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my $filter = +{ namespace => $param->{namespace}, status => $param->{status} };
    my $argv = $param->{namespace} ? "-n $param->{namespace}" : "-A";
#TODO 不添加2>/dev/null 时,如果命名空间不存在service时，api.event 的接口会报错
    my ( $cmd, $handle ) = ( "$kubectl get service -o wide $argv 2>/dev/null", 'getservice' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
};

$handle{getservice} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my @x = split /\n/, $x;

    my $failonly = ( $filter->{status} && $filter->{status} eq 'fail' ) ? 1 : 0;

    my $title = shift @x;
    $title =~ s/PORT\(S\)/PORT_S/;
    $title =~ s/\-/_/g;
    my ( @title, @r ) = split /\s+/, $title;
    unshift @title, 'NAMESPACE' if $filter->{namespace};

    map
    {
         my @col = split /\s+/, $_;
         unshift @col, $filter->{namespace} if $filter->{namespace};
         my %r = map{ $title[$_] => $col[$_] }0..$#title;
         push @r, \%r if ( ! $failonly) || ( $failonly && $r{ENDPOINTS} eq '<none>' );
    }@x;

    return +{ stat => $JSON::true, data => \@r, };
};

true;
