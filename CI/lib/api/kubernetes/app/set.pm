package api::kubernetes::app::set;
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

=pod

K8S/修改镜像地址

对应K8S中的set image命令

=cut

post '/kubernetes/app/set/image' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        container => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        image => qr/^[\w@\.\-\/:]*$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'KUBERNETES SET IMAGE', content => "ticketid:$param->{ticketid} namespace:$param->{namespace} container:$param->{container} image:$param->{image}" ); };

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $param->{namespace} }@ns;

    my ( $cmd, $handle ) = ( "$kubectl set image '$param->{type}/$param->{name}' '$param->{container}=$param->{image}' -n '$param->{namespace}' 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

=pod

K8S/调整福本数

=cut

post '/kubernetes/app/set/replicas' => sub {
    my $param = params();
    my $error = Format->new( 
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        replicas => qr/\d+$/, 1,
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'KUBERNETES SET REPLICAS', content => "ticketid:$param->{ticketid} namespace:$param->{namespace} name:$param->{name} replicas:$param->{replicas}" ); };

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $param->{namespace} }@ns;

    my ( $cmd, $handle ) = ( "$kubectl scale '$param->{type}' '$param->{name}' -n '$param->{namespace}' --replicas=$param->{replicas} 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

true;
