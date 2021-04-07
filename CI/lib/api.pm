package api;
use Dancer ':syntax';
use JSON;
use FindBin qw( $RealBin );
use MYDB;
use Code;
use Logs;
use Util;

set serializer => 'JSON';
set show_errors => 1;

our $VERSION = '0.1';
our ( $mysql, $sso, $myname, $pms, $cookiekey, $logs, $auditlog );

BEGIN{
    $myname = Util::myname();
    $mysql = MYDB->new( "$RealBin/../conf/conn" );

    ( $sso, $pms ) = map{ Code->new( "auth/$_" ) }qw( sso pms );

    my %env = Util::envinfo( qw( cookiekey ) );
    $cookiekey = $env{cookiekey};

    $logs = Logs->new( 'api' );

    $auditlog = Code->new( 'auditlog' );
};

hook 'before' => sub {
    header "Access-Control-Allow-Headers" => "u,appkey,appname";
    return if $ENV{MYDan_DEBUG};

    my $uri = request->path_info;
    return if $uri =~ m{^/mon} || $uri =~ m{^/release} || $uri =~ m{^/webhooks};

    halt( +{ stat => $JSON::false, code => 10000 } ) 
        unless (  cookie( $cookiekey ) || ( request->headers->{appkey} && request->headers->{appname} ) );
 
    my $user = eval{ $sso->run( cookie => cookie( $cookiekey ), 
            map{ $_ => request->headers->{$_} }qw( appkey appname ) ) };
    halt( +{ stat => $JSON::false, info => "sso code error:$@" } ) if $@;
    halt( +{ stat => $JSON::false, code => 10000 } ) unless $user;

#    $logs->say( sprintf "user:$user uri:$uri method:%s HTTP_X_FORWARDED_FOR:%s param:%s", 
#        request->method, request->env->{HTTP_X_FORWARDED_FOR}, YAML::XS::Dump YAML::XS::Dump request->params() );
#
#    my $p = eval{ $pms->run( cookie => cookie( $cookiekey ), uri => $uri,
#            method => request->method, map{ $_ => request->headers->{$_} }qw( appkey appname ) ) };
#    halt( +{ stat => $JSON::false, info => "pms code error:$@" } ) if $@;
#    halt( +{ stat => $JSON::false, info =>  'Unauthorized' } ) unless $p;
};

hook before_error_render => sub {
     my $error = shift;
     $error->{message} = { 
         stat => $JSON::false, 
         info => $error->exception
    };
};

any '/mon' => sub {
    eval{ $mysql->query( "select count(*) from keepalive" )};
    return $@ ? "ERR:$@" : "ok";
};

sub pmscheck
{
    my ( $point, $treeid ) = @_;
    my $p = eval{ $pms->run( cookie => cookie( $cookiekey ), point => $point, treeid => $treeid,
        map{ $_ => request->headers->{$_} }qw( appkey appname ) ) };
    return +{ stat => $JSON::false, info => "pms code error:$@" } if $@;
    return +{ stat => $JSON::false, info =>  'Unauthorized' } unless $p;
    return 0;
}

true;
