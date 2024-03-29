package api;
use Dancer  ':syntax';
use JSON    qw();
use FindBin qw( $RealBin );
use MYDB;
use Code;
use Util;
use point;

set serializer  => 'JSON';
set show_errors => 1;

our $VERSION = '0.1';
our (
    $mysql,   $myname,     $sso,       $ssologout,  $ssoconfig,
    $pms,     $cookiekey,  $pmslocal,  $approvesso, $approvessologout
);

BEGIN{
    $myname = Util::myname();
    $mysql = MYDB->new( "$RealBin/../conf/conn" );

    ( $ssologout,        $sso, $pms  ) = map{ Code->new( "connectorx.plugin/$_"         ) }qw( ssologout sso point );
    ( $approvessologout, $approvesso ) = map{ Code->new( "connectorx.plugin/approve/$_" ) }qw( ssologout sso       );

    $ssoconfig = Code->new( "auth/ssoconfig" )->run();
    die "cookiekey undef" unless $cookiekey = $ssoconfig->{cookiekey};

    $pmslocal = ( $ssoconfig->{pmspoint} && $ssoconfig->{pmspoint} =~ m{http://api.connector.open-c3.org/default/auth} ) ? 1 : 0;
};

hook 'before' => sub {
    my ( $uri, $method ) = ( request->path_info, request->method );
    return if
        $uri =~ m{^/mon}
     || $uri =~ m{^/sso}
     || $uri =~ m{^/pms}
     || $uri =~ m{^/default/sso}
     || $uri =~ m{^/internal/sso}
     || $uri =~ m{^/default/tree}
     || $uri =~ m{^/sso/userauth/point/}
     || $uri =~ m{^/reload};
};

hook before_error_render => sub {
     my $error = shift;
     $error->{message} = { 
         stat => $JSON::false, 
         info => $error->exception
    };
};

any '/mon' => sub {
    eval{ $mysql->query( "select count(*) from openc3_connector_keepalive" )};
    return $@ ? "ERR:$@" : "ok";
};

any '/reload' => sub {
    my $token = `cat /etc/openc3.reload.token 2>/dev/null`; chomp $token;
    return 'err' unless request->headers->{token} && $token && request->headers->{token} eq $token;
    exit;
};

sub ssocheck
{
    my $cookie = params()->{cookie} || cookie( $cookiekey );

    return +{ stat => $JSON::false, code => 10000 }
        unless ( $cookie || ( request->headers->{appkey} && request->headers->{appname} ) );
 
    my $user = eval{ $sso->run( cookie => $cookie, map{ $_ => request->headers->{$_} }qw( appkey appname ) ) };
    return +{ stat => $JSON::false, info => "sso code error:$@" } if $@;
    return +{ stat => $JSON::false, code => 10000 } unless $user;

    return ( undef, $user );
}

sub pmscheck
{
    my $cookie = params()->{cookie} || cookie( $cookiekey );
    my ( $point, $treeid ) = @_;

    if( $pmslocal && !( request->headers->{appkey} && request->headers->{appname} ) )
    {
        my $user = eval{ $sso->run( cookie => $cookie ) };
        return +{ stat => $JSON::false, info => "sso code error:$@" } if $@;

        my ( $err, $s ) = point::point( $mysql, $point, $treeid, $user );

        return +{ stat => $JSON::false, info => $err } if $err;
        return +{ stat => $JSON::false, info =>  'Unauthorized' } unless $s;
        return 0;
    }

    my $p = eval{ $pms->run( cookie => $cookie, point => $point, treeid => $treeid,
        map{ $_ => request->headers->{$_} }qw( appkey appname ) ) };
    return +{ stat => $JSON::false, info => "pms code error:$@" } if $@;
    return +{ stat => $JSON::false, info =>  'Unauthorized' } unless $p;
    return 0;
}

true;
