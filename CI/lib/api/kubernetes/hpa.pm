package api::kubernetes::hpa;
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

K8S/HPA/获取集群HPA列表

=cut

get '/kubernetes/hpa' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 0 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    my $filter = \@ns;
    my ( $cmd, $handle ) = ( "$kubectl get  hpa -A 2>/dev/null", 'gethpa' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle, filter => $filter }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $?, $filter ); 
 };

$handle{gethpa} = sub
{
    my ( $x, $status, $filter ) = @_;
    return +{ stat => $JSON::false, data => $x } if $status;
    my @x = split /\n/, $x;

    my %r;
    my @title = split /\s+/, shift @x;
    for( @x )
    {
        my @col = split /\s+/;
        my %tmp = map { $title[$_] => $col[$_] }0.. $#title;
        $tmp{describe} = sprintf "%s : %s - %s", @tmp{qw(TARGETS MINPODS MAXPODS)}; 
        my $n = $tmp{REFERENCE};
        $n =~ s/^Deployment/deployment.apps/;
        $r{$tmp{NAMESPACE}}{$n} = \%tmp;
    }

    if( $filter && ref $filter eq 'ARRAY' && @$filter )
    {
        my %keep = map{$_ => 1 }@$filter;
        for my $k ( keys %r )
        {
            delete $r{$k} unless $keep{$k};
        }
    }

    return +{
        stat => $JSON::true,
        data => \%r
    };
};

=pod

K8S/HPA/创建

=cut

post '/kubernetes/hpa/create' => sub {
    my $param = params();
    my $error = Format->new( 
        ticketid => qr/^\d+$/, 1,
        namespace => qr/^[\w@\.\-]*$/, 1,
        type => qr/^[\w@\.\-]*$/, 1,
        name => qr/^[\w@\.\-]*$/, 1,

        min => qr/^\d+$/, 1,
        max => qr/^\d+$/, 1,

        cpu => qr/^\d+$/, 1,
    )->check( %$param );

    return  +{ stat => $JSON::false, info => "check format fail $error" } if $error;
    my $pmscheck = api::pmscheck( 'openc3_ci_read', 0 ); return $pmscheck if $pmscheck;

    my ( $user, $company )= $api::sso->run( cookie => cookie( $api::cookiekey ), 
        map{ $_ => request->headers->{$_} }qw( appkey appname ));

    eval{ $api::auditlog->run( user => $user, title => 'KUBERNETES SET HPA', content => "ticketid:$param->{ticketid} namespace:$param->{namespace} type:$param->{type} name:$param->{name} min:$param->{min} max:$param->{max} cpu:$param->{cpu}" ); };

    my ( $kubectl, @ns ) = eval{ api::kubernetes::getKubectlAuth( $api::mysql, $param->{ticketid}, $user, $company, 1 ) };
    return +{ stat => $JSON::false, info => "get ticket fail: $@" } if $@;

    return +{ stat => $JSON::false, info => "no auth" } if @ns && ! grep{ $_ eq $param->{namespace} }@ns;

    my ( $cmd, $handle ) = ( "$kubectl autoscale '$param->{type}' '$param->{name}' --min $param->{min} --max $param->{max} --cpu-percent=$param->{cpu} -n '$param->{namespace}' 2>&1", 'showinfo' );
    return +{ stat => $JSON::true, data => +{ kubecmd => $cmd, handle => $handle }} if request->headers->{"openc3event"};
    return &{$handle{$handle}}( Encode::decode_utf8(`$cmd`//''), $? ); 
};

true;
