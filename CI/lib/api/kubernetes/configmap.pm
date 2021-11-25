package api::kubernetes::configmap;
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
use api::kubernetes;

our %handle;
$handle{showinfo} = sub { return +{ info => shift, stat => shift ? $JSON::false : $JSON::true }; };

get '/kubernetes/configmap' => sub {
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

    my ( $cmd, $handle ) = ( "$kubectl get configmap -A ", 'getconfigmap' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? );
 };

$handle{getconfigmap} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my @x = split /\n/, $x;

    my @r;
    my @title = split /\s+/, shift @x;
    for( @x )
    {
        my @col = split /\s+/;
        my %tmp = map { $title[$_] => $col[$_] }0.. $#title;
        push @r, \%tmp;
    }
    return +{ stat => $JSON::true, data => \@r, };
};

##TODO 未启用，目前用的apply接口
post '/kubernetes/configmap/create' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        server => qr/^[\w@\.\-]*$/, 1,
        username => qr/^[\w@\.\-]*$/, 1,
        password => qr/^[\w@\.\-]*$/, 1,
        email => qr/^[\w@\.\-]*$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my $email = $param->{email} ? "--docker-email='$param->{email}'" : "";
    my ( $cmd, $handle ) = ( "$kubectl create configmap docker-registry '$param->{name}' --docker-server='$param->{server}' --docker-username='$param->{username}' --docker-password='$param->{password}' $email -n '$param->{namespace}' 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

true;
