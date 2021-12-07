package api::kubernetes::ingress;
use Dancer ':syntax';
use Dancer qw(cookie);
use Encode qw(encode);
use FindBin qw( $RealBin );
use JSON;
use POSIX;
use api;
use Format;
use MIME::Base64;
use Time::Local;
use File::Temp;
use api::kubernetes;

our %handle = %api::kubernetes::handle;

get '/kubernetes/ingress' => sub {
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
#TODO 不添加2>/dev/null 时,如果命名空间不存在ingress时，api.event 的接口会报错
    my ( $cmd, $handle ) = ( "$kubectl get ingress -o wide $argv 2>/dev/null", 'getingress' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( `$cmd`//'', $?, $filter );
};

$handle{getingress} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my @x = split /\n/, $x;

    return +{ stat => $JSON::true, data => [] } unless @x;

    my $failonly = ( $filter->{status} && $filter->{status} eq 'fail' ) ? 1 : 0;

    my ( @title, @r ) = split /\s+/, shift @x;
    unshift @title, 'NAMESPACE' if $filter->{namespace};
    splice @title,4, 0, splice @title, -2;

    map
    {
         $_ =~ s/, /,/g;
         $_ = "$filter->{namespace} $_" if $filter->{namespace};
         my @col = split /\s+/, $_, 4;

         my %r; map{ $r{$title[$_]} = $col[$_] }0..2;
         my @tempcol = split /\s+/, pop @col;
         $r{AGE} = pop @tempcol;
         $r{PORTS} = pop @tempcol if @tempcol && $tempcol[-1] =~ /^[\d\,]+$/;
         ( $r{HOSTS}, $r{ADDRESS} ) = split /\s+/, join( ' ', @tempcol ), 2;
         if( $r{ADDRESS} && $r{ADDRESS} =~ s/^(\+ \d+ more\.\.\.)// )
         {
             $r{HOSTS} .= $1;
         }
         
        push @r, \%r if ( ! $failonly) || ( $failonly && ! $r{ADDRESS} );
    }@x;

    return +{ stat => $JSON::true, data => \@r, };
};

get '/kubernetes/app/ingress/dump' => sub {
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my ( $cmd, $handle ) = ( "/data/Software/mydan/CI/bin/kubectl-searchingress '$user' '$company' 2>/dev/null", 'getsearchingress' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};

    return &{$handle{$handle}}( `$cmd`//'', $? ); 
};

$handle{getsearchingress} = sub
{
    my ( $x, $status ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;

    my $data = eval{ YAML::XS::Load $x };
    return +{ stat => $JSON::false, info => $@ } if $@;

    map{ $_->{clustername} = decode_base64( $_->{clustername} ) }@$data;
    return +{ stat => $JSON::true, data => $data };
};

true;
