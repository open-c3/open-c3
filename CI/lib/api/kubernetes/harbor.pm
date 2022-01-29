package api::kubernetes::harbor;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use JSON qw();
use POSIX;
use api;
use Format;
use MIME::Base64;
use Time::Local;
use File::Temp;
use api::kubernetes;

our %handle = %api::kubernetes::handle;

get '/kubernetes/harbor/repository' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ),
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my ( $cmd, $handle ) = ( "/data/Software/mydan/CI/bin/harbor-searchimage $param->{ticketid} '$user' '$company' 2>/dev/null", 'getsearchharborimage' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

$handle{getsearchharborimage} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;

    my $data = eval{ YAML::XS::Load $x };
    return +{ stat => $JSON::false, info => $@ } if $@;
    return +{ stat => $JSON::true, data => $data };
};

true;
