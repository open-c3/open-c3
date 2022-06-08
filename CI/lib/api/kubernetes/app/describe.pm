package api::kubernetes::app::describe;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use MIME::Base64;
use FindBin qw( $RealBin );
use JSON qw();
use POSIX;
use api;
use Format;
use Time::Local;
use File::Temp;
use api::kubernetes;

our %handle = %api::kubernetes::handle;

get '/kubernetes/app/describe' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my %available = map{ $_ => 1 }qw( ingress service deployment daemonset pod replicaset hpa endpoints job statefulset );
    my $auth = $available{$param->{type}} ? 0 : 1;

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, $auth ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $param->{namespace} }@ns;

    my ( $cmd, $handle ) = ( "$kubectl describe '$param->{type}' '$param->{name}' -n '$param->{namespace}' 2>/dev/null", 'showdata' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

get '/kubernetes/app/describe/deployment' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my ( $kubectl, @ns )= eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $param->{namespace} }@ns;

    my ( $cmd, $handle ) = ( "/data/Software/mydan/CI/bin/kubectl-describedeployment '$kubectl' '$param->{namespace}' '$param->{name}' 2>/dev/null", 'getdescribedeployment' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

$handle{getdescribedeployment} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;

    my $data = eval{ YAML::XS::Load Encode::encode('utf8', $x ) };
    return +{ stat => $JSON::false, info => $@, xx => $x } if $@;

    return +{ stat => $JSON::true, data => $data };
};

get '/kubernetes/app/describe/ingress' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $param->{namespace} }@ns;

    my ( $cmd, $handle ) = ( "/data/Software/mydan/CI/bin/kubectl-describeingress '$kubectl' '$param->{namespace}' '$param->{name}' 2>/dev/null", 'getdescribeingress' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

$handle{getdescribeingress} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;

    my $data = eval{ YAML::XS::Load Encode::encode('utf8', $x ) };
    return +{ stat => $JSON::false, info => $@, xx => $x } if $@;

    return +{ stat => $JSON::true, data => $data };
};

get '/kubernetes/app/describe/service' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $param->{namespace} }@ns;

    my ( $cmd, $handle ) = ( "/data/Software/mydan/CI/bin/kubectl-describeservice '$kubectl' '$param->{namespace}' '$param->{name}' 2>/dev/null", 'getdescribeservice' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

$handle{getdescribeservice} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;

    my $data = eval{ YAML::XS::Load Encode::encode('utf8', $x ) };
    return +{ stat => $JSON::false, info => $@, xx => $x } if $@;

    return +{ stat => $JSON::true, data => $data };
};

post '/kubernetes/app/describe/ecs' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    return  +{ stat => $JSON::false, info => "no param cmd" } unless $param->{cmd};
    my $cmdconf = eval{ YAML::XS::Load $param->{cmd} };
    return +{ stat => $JSON::false, info => "param cmd toyaml fail:$@" } if $@;
    map{
        return  +{ stat => $JSON::false, info => "param cmd err: $_ = $cmdconf->{$_}" }
            unless $cmdconf->{$_} && $cmdconf->{$_} =~ /^[a-zA-Z][a-zA-Z0-9\.\-_@]+$/;
    } qw( region service cluster );

    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my $taskdefinition = $cmdconf->{'task-definition'};
    my ( $cmd, $handle ) = ( "c3mc-aws-ecs-describe -i '$param->{ticketid}' --region '$cmdconf->{region}' --services '$cmdconf->{service}' --cluster  '$cmdconf->{cluster}' --taskdefinition '$taskdefinition' 2>/dev/null", 'getdescribeecs' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

$handle{getdescribeecs} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my $data = eval{ YAML::XS::Load Encode::encode('utf8', $x ) };
    return +{ stat => $JSON::false, info => $@, xx => $x } if $@;
    return +{ stat => $JSON::true, data => $data };
};

true;
