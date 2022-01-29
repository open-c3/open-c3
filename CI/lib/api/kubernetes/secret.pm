package api::kubernetes::secret;
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

get '/kubernetes/secret' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 0,
        skip => qr/^[\w@\.\-\/,]*$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my $argv = $param->{namespace} ? "-n '$param->{namespace}'" : "-A";
    my $filter = +{ skip => $param->{skip} };
    my ( $cmd, $handle ) = ( "$kubectl get secrets $argv 2>/dev/null", 'getsecret' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $?, $filter );
 };

$handle{getsecret} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;

    my %skip; map{ $skip{$_} = 1 } split( /,/, $filter->{skip}) if $filter->{skip};
    my ( @x, @r ) = split /\n/, $x;
    my @title = split /\s+/, shift @x;
    for( @x )
    {
        my @col = split /\s+/;
        my %tmp = map { $title[$_] => $col[$_] } 0 .. $#title;
        push @r, \%tmp unless $skip{$tmp{TYPE}};
    }
    return +{ stat => $JSON::true, data => \@r, };
};

post '/kubernetes/secret/dockerconfigjson' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        server => qr/^[\w@\.\-]*$/, 1,
        username => qr/^[\w@\.\-]*$/, 1,
        password => [ 'mismatch', qr/'/ ], 1,
        email => qr/^[\w@\.\-]*$/, 0,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my $kubectl = eval{ api::kubernetes::getKubectlCmd( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my $email = $param->{email} ? "--docker-email='$param->{email}'" : "";
    my ( $cmd, $handle ) = ( "$kubectl create secret docker-registry '$param->{name}' --docker-server='$param->{server}' --docker-username='$param->{username}' --docker-password='$param->{password}' $email -n '$param->{namespace}' 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

true;
